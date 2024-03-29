# frozen_string_literal: true

class Boutique::OrdersController < Boutique::ApplicationController
  include Boutique::RedirectAfterOrderPaid

  VOUCHER_GET_PARAM_NAME = :c

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

    @use_boutique_adaptive_css = true
  end

  def refreshed_edit
    order = current_order

    country_code = params.require(:country_code)

    if order.primary_address.blank?
      order.build_primary_address(country_code:)
    else
      order.primary_address.country_code = country_code
    end

    render json: {
      data: {
        sidebarBottom: cell("boutique/orders/edit/sidebar/bottom", order).show,
        price: cell("boutique/orders/payment_methods/price", order.total_price).show,
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

    current_order.transaction do
      if current_order.confirm!
        if current_order.free?
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
                                  product_variant_id
                                  subscription_starts_at
                                  subscription_recurring]
      ]
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
