# frozen_string_literal: true

class Boutique::CheckoutController < Boutique::ApplicationController
  include Boutique::CreatePaymentAndRedirect
  include Boutique::RedirectAfterOrderPaid

  before_action :raise_record_not_found_if_current_order_is_empty, only: %i[remove_item]
  before_action :redirect_if_current_order_is_empty, except: %i[add_item cart refreshed_cart crossdomain_add_item]

  def crossdomain_add_item
    add_item_to_order_and_redirect
  end

  def add_item
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
    if current_order.nil? || current_order.line_items.empty?
      render json: {}
      return
    end

    if country_code = params[:country_code].presence
      if current_order.primary_address.blank?
        current_order.build_primary_address(country_code:)
      else
        current_order.primary_address.country_code = country_code
      end
    end

    if shipping_method_id = params[:shipping_method_id].presence
      shipping_method = Boutique::ShippingMethod.published.find_by_id(shipping_method_id)
      current_order.shipping_method = shipping_method if shipping_method.present?
    end

    subscription_period = params[:subscription_period] || nil
    subscription_recurring = params[:subscription_recurring] == "true"

    current_order.line_items.each do |line_item|
      line_item.subscription_period = subscription_period
      line_item.subscription_recurring = subscription_recurring
    end

    render json: {
      data: {
        summary: cell("boutique/orders/summary", current_order).show,
        price: cell("boutique/orders/payment_methods/price", current_order.total_price, recurrent: current_order.recurrent_payment?).show,
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
          redirect_after_order_paid(current_order)
        else
          create_payment_and_redirect_to_payment_gateway(current_order)
        end
      else
        if current_order.errors[:base].present?
          flash.now[:alert] = current_order.errors[:base].join(", ")
        end

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
                                    :gift_recipient_notification_scheduled_for,
                                    :shipping_method_id,
                                    :pickup_point_remote_id,
                                    :pickup_point_title,
                                    :terms_agreement,
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
                                  subscription_period]
      ]
    end

    def raise_record_not_found_if_current_order_is_empty
      raise ActiveRecord::RecordNotFound if current_order.nil?
    end

    def redirect_if_current_order_is_empty
      redirect_back fallback_location: main_app.root_url if current_order.nil?
    end

    def add_item_to_order_and_redirect
      product = Boutique::Product.find(params.require(:product_slug))

      if params[:product_variant_id].present?
        product_variant = product.variants.find(params[:product_variant_id])
      else
        product_variant = product.master_variant
      end

      create_current_order if current_order.nil?

      if params[:gift].present?
        current_order.update!(gift: true)
      end

      current_order.add_line_item!(product_variant, **add_line_item_options)

      redirect_to action: :cart
    end

    def add_line_item_options
      options = {}
      options[:amount] = params[:amount].to_i if params[:amount].present?
      options
    end
end
