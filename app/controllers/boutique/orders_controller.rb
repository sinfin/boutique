# frozen_string_literal: true

class Boutique::OrdersController < Boutique::ApplicationController
  include Boutique::RedirectAfterOrderPaid

  before_action :redirect_if_current_order_is_empty, except: %i[add show crossdomain_add payment]
  before_action :find_order_by_secret_hash, only: %i[show payment]

  def crossdomain_add
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

    add_to_order_and_redirect
  end

  def add
    if url_name = ::Boutique.config.after_order_paid_user_url_name
      session[:boutique_after_order_paid_user_url] = main_app.send(url_name,
                                                                   host: current_site.env_aware_domain,
                                                                   only_path: false)
    end

    add_to_order_and_redirect
  end

  def edit
    @use_boutique_adaptive_css = true
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
                                    :gift_recipient_notification_scheduled_for,
                                    :recurring_payment_agreement,
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

    def find_order_by_secret_hash
      @order = Boutique::Order.except_pending.find_by!(secret_hash: params[:id])
    end

    def add_to_order_and_redirect
      product_variant = Boutique::ProductVariant.find(params.require(:product_variant_slug))
      amount = params[:amount].to_i if params[:amount].present?

      create_current_order if current_order.nil?

      current_order.add_line_item!(product_variant, amount: amount || 1)

      redirect_to action: :edit
    end
end
