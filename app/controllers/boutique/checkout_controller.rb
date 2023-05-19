# frozen_string_literal: true

class Boutique::CheckoutController < Boutique::ApplicationController
  include Boutique::CreatePaymentAndRedirect
  include Boutique::RedirectAfterOrderPaid

  before_action :raise_record_not_found_if_current_order_is_empty, only: %i[remove_item]
  before_action :redirect_if_current_order_is_empty, except: %i[add_item cart refreshed_cart crossdomain_add_item]

  def crossdomain_add_item
    add_item_to_order_and_redirect

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

  def add_item
    if custom_url = custom_boutique_after_order_paid_user_url
      session[:boutique_after_order_paid_user_url] = custom_url
    else
      if url_name = ::Boutique.config.after_order_paid_user_url_name
        session[:boutique_after_order_paid_user_url] = main_app.send(url_name,
                                                                     host: current_site.env_aware_domain,
                                                                     only_path: false)
      end
    end

    add_item_to_order_and_redirect
  end

  def remove_item
    line_item = current_order.line_items.find(params[:line_item_id])

    unless line_item.destroy
      flash[:alert] = t(".error")
    end

    redirect_to action: :cart
  end

  def cart
    @public_page_title = t(".public_page_title")

    @use_boutique_adaptive_css = true
  end

  def refreshed_cart
    country_code = params.require(:country_code)

    if current_order.nil? || current_order.line_items.empty?
      render json: {}
      return
    end

    if current_order.primary_address.blank?
      current_order.build_primary_address(country_code:)
    else
      current_order.primary_address.country_code = country_code
    end

    render json: {
      data: {
        sidebarBottom: cell("boutique/orders/cart/sidebar/bottom", current_order).show,
        price: cell("boutique/orders/payment_methods/price", current_order.total_price).show,
      }
    }
  end

  def apply_voucher
    @use_boutique_adaptive_css = true

    current_order.assign_voucher_by_code(params[:voucher_code])

    respond_to do |format|
      format.html do
        if current_order.errors.blank?
          flash.now[:success] = t(".success")
        else
          flash.now[:alert] = t(".invalid_code")
        end

        render :cart
      end

      format.json do
        render json: {
          data: cell("boutique/orders/cart").show
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
        render :cart
      end
    end
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
                                  boutique_product_variant_id
                                  subscription_starts_at
                                  subscription_recurring
                                  subscription_recurring_period]
      ]
    end

    def raise_record_not_found_if_current_order_is_empty
      raise ActiveRecord::RecordNotFound if current_order.nil?
    end

    def redirect_if_current_order_is_empty
      redirect_back fallback_location: main_app.root_url if current_order.nil?
    end

    def custom_boutique_after_order_paid_user_url
      nil
    end

    def add_item_to_order_and_redirect
      product = Boutique::Product.find(params.require(:product_slug))

      if params[:product_variant_id].present?
        product_variant = product.variants.find(params[:product_variant_id])
      else
        product_variant = product.master_variant
      end

      create_current_order if current_order.nil?

      current_order.add_line_item!(product_variant, **add_line_item_options)

      redirect_to action: :cart
    end

    def add_line_item_options
      options = {}
      options[:amount] = params[:amount].to_i if params[:amount].present?
      options
    end
end
