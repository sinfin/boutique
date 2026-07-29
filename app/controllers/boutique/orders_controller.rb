# frozen_string_literal: true

class Boutique::OrdersController < Boutique::ApplicationController
  include Boutique::RedirectAfterOrderPaid

  VOUCHER_GET_PARAM_NAME = :c
  INTRO_DENIAL_SESSION_KEY = :boutique_intro_denied_order_id

  before_action :redirect_if_current_order_is_empty, except: %i[add show crossdomain_add payment]
  before_action :redirect_if_current_order_is_unavailable, except: %i[add show crossdomain_add payment]
  before_action :find_order_by_secret_hash, only: %i[show payment]

  def crossdomain_add
    add_to_order_and_redirect

    if custom_url = custom_boutique_after_order_paid_user_url
      session[:boutique_after_order_paid_user_url] = custom_url
    else
      if request.referrer.present?
        clean_referrer_domain = request.referrer.gsub(%r{\Ahttps?://}, "").gsub(%r{/.*\z}, "")

        if Folio::Site.all.any? { |site| site.env_aware_domain == clean_referrer_domain }
          if url_name = ::Boutique.config.after_order_paid_user_url_name
            session[:boutique_after_order_paid_user_url] = main_app.send(url_name,
                                                                         host: clean_referrer_domain,
                                                                         only_path: false)


          end
        end
      end
    end
  end

  def add
    if custom_url = custom_boutique_after_order_paid_user_url
      session[:boutique_after_order_paid_user_url] = custom_url
    else
      if url_name = ::Boutique.config.after_order_paid_user_url_name
        session[:boutique_after_order_paid_user_url] = main_app.send(url_name,
                                                                     host: current_site.env_aware_domain,
                                                                     only_path: false)
      end
    end

    add_to_order_and_redirect
  end

  def edit
    if params[VOUCHER_GET_PARAM_NAME]
      current_order.assign_voucher_by_code(params[VOUCHER_GET_PARAM_NAME])
    end

    # a signed in customer is recognized right away, so they get told the moment
    # they arrive rather than after filling the whole checkout in
    if message = denied_intro_message
      flash.now[:warning] = message
      mark_intro_denial_as_seen
    end

    @use_boutique_adaptive_css = true
  end

  def refreshed_edit
    order = current_order

    if order.requires_address?
      country_code = params.require(:country_code)

      if order.primary_address.blank?
        order.build_primary_address(country_code:)
      else
        order.primary_address.country_code = country_code
      end
    end

    if params[:line_item_amount]
      order.line_item.amount = params[:line_item_amount]
    end

    if shipping_method_id = params[:shipping_method_id].presence
      shipping_method = Boutique::ShippingMethod.published.find_by_id(shipping_method_id)
      order.shipping_method = shipping_method if shipping_method.present?
      order.pickup_point_country_code = params[:pickup_point_country_code].presence
    end

    shipping_methods_data = order.allowed_shipping_methods.published.to_h do |sm|
      [sm.id, cell("boutique/orders/edit/shipping_methods/label", sm, country_code: order.primary_address&.country_code).show]
    end

    render json: {
      data: {
        shippingMethods: shipping_methods_data,
        sidebarBottom: cell("boutique/orders/edit/sidebar/bottom", order).show,
        price: cell("boutique/orders/payment_methods/price", order).show,
        voucherFields: cell("boutique/orders/edit/voucher_fields", nil, order:).show,
      }
    }
  end

  def apply_voucher
    @use_boutique_adaptive_css = true

    unless current_order.voucher.present?
      current_order.assign_voucher_by_code(params[:voucher_code])
    end

    respond_to do |format|
      format.html do
        if current_order.errors.blank?
          flash.now[:success] = t(".success")
        else
          flash.now[:alert] = t(".invalid_code")
        end

        render :edit
      end
      format.json do
        render json: {
          data: cell("boutique/orders/edit").show
        }, status: 200

        # if current_order.errors.blank?
        # else
        #   errors = [
        #     {
        #       status: 400,
        #       title: "ActiveRecord::RecordInvalid",
        #       title: t('.invalid_code'),
        #     }
        #   ]

        #   render json: { errors: }, status: 400
        # end
      end
    end
  end

  def confirm
    @use_boutique_adaptive_css = true

    current_order.force_address_validation = true if current_order.requires_address?
    current_order.force_gift_recipient_notification_scheduled_for_validation = true
    current_order.assign_attributes(order_params)

    # the e-mail just told us who the customer is and the introductory offer may
    # not apply to them - back to the checkout, which now prices the order
    # regularly and says why, instead of straight to the payment gateway
    if !intro_denial_seen? && current_order.denied_intro_line_item.present?
      # keep what the customer filled in, both to spare them retyping it and so
      # that the checkout keeps recognizing them on every further request
      current_order.save(validate: false)

      redirect_to action: :edit and return
    end

    current_order.transaction do
      if current_order.confirm!
        # a free introductory subscription still needs the card authorized,
        # see Boutique::Order#zero_amount_authorization?
        if current_order.free? && !current_order.zero_amount_authorization?
          current_order.pay!

          flash[:success] = t(".success_free")
          redirect_after_order_paid(current_order)
        else
          create_payment_and_redirect_to_payment_gateway(current_order)
        end
      else
        render :edit
      end
    end
  end

  def show
    @use_boutique_adaptive_css = :no_background
  end

  def payment
    # TODO: check if order has been paid
    create_payment_and_redirect_to_payment_gateway(@order)
  end

  private
    def order_params
      params.require(:order).permit(:email,
                                    :first_name,
                                    :last_name,
                                    :voucher_code,
                                    :gift,
                                    :gift_recipient_email,
                                    :gift_recipient_first_name,
                                    :gift_recipient_last_name,
                                    :gift_recipient_notification_scheduled_for,
                                    :shipping_method_id,
                                    :pickup_point_id,
                                    :pickup_point_country_code,
                                    :pickup_point_title,
                                    :age_verification,
                                    *addresses_strong_params,
                                    *line_items_strong_params)
    end

    def addresses_strong_params
      base = %i[id
                name
                company_name
                address_line_1
                address_line_2
                city
                zip
                country_code
                phone
                email
                identification_number
                vat_identification_number]

      [
        :use_secondary_address,
        primary_address_attributes: base,
        secondary_address_attributes: base,
      ]
    end

    def line_items_strong_params
      [
        line_items_attributes: %i[id
                                  amount
                                  product_variant_id
                                  subscription_starts_at
                                  subscription_recurring]
      ]
    end

    # The introductory price is a new customer offer and the checkout only learns
    # who the customer is once they sign in or fill their e-mail in. Whenever the
    # offer turns out not to apply, the line item falls back to the regular price
    # on its own - this is the only place that says so out loud.
    def denied_intro_message
      line_item = current_order.denied_intro_line_item
      return if line_item.nil?

      t("boutique.orders.intro_denied.#{line_item.product.intro_free? ? 'trial' : 'discounted'}")
    end

    # Once the customer has seen the regular price in the checkout, confirming is
    # up to them - #confirm stops turning them back.
    def mark_intro_denial_as_seen
      session[INTRO_DENIAL_SESSION_KEY] = current_order.id
    end

    def intro_denial_seen?
      session[INTRO_DENIAL_SESSION_KEY] == current_order.id
    end

    def create_payment_and_redirect_to_payment_gateway(order)
      gp_payment = Boutique::GoPay::Api.new.create_payment(order, controller: self,
                                                                  payment_method: params[:payment_method])
      order.payments.create!(remote_id: gp_payment["id"],
                             payment_method: gp_payment["payment_instrument"])

      redirect_to gp_payment["gw_url"], allow_other_host: true
    end

    def redirect_if_current_order_is_empty
      redirect_back fallback_location: main_app.root_url if current_order.nil?
    end

    def redirect_if_current_order_is_unavailable
      if current_order.line_items.any? { |li| !li.product.published? }
        flash[:alert] = t(".flash.product_unavailable")
        redirect_back fallback_location: main_app.root_url
      end
    end

    def find_order_by_secret_hash
      @order = Boutique::Order.except_pending.find_by!(secret_hash: params[:id])
    end

    def custom_boutique_after_order_paid_user_url
      nil
    end

    def add_to_order_and_redirect
      @product = Boutique::Product.find(params.require(:product_slug))

      amount = params[:amount].to_i if params[:amount].present?

      if current_user && params[:subscription_id].present?
        subscription = current_user.subscriptions.find_by_id(params[:subscription_id])
      end

      create_current_order if current_order.nil?

      current_order.add_line_item!(@product, amount: amount || 1,
                                             renewed_subscription: subscription,
                                             additional_options: add_line_item_additional_options)

      if params[VOUCHER_GET_PARAM_NAME]
        current_order.assign_voucher_by_code(params[VOUCHER_GET_PARAM_NAME])
      end

      redirect_to action: :edit, VOUCHER_GET_PARAM_NAME => params[VOUCHER_GET_PARAM_NAME]
    end

    def add_line_item_additional_options
      {}
    end
end
