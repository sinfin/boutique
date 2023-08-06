# frozen_string_literal: true

class Boutique::PaymentGateway
  attr_reader :provider, :provider_gateway

  DEFAULT_PAYMENT_METHOD = "PAYMENT_CARD"

  class Error < StandardError
    attr_accessor :stopped_recurrence
  end

  ResponseStruct = Struct.new(:transaction_id, :redirect_to, :hash, :array, keyword_init: true) do
    def redirect?
      !redirect_to.nil?
    end
  end

  def self.process_callback(params, provider: nil)
    provider ||= params["transId"].present? ? :comgate : :go_pay

    case provider
    when :comgate
      # :comgate DO NOT CheckTransaction in process_callback
      gw = Boutique::PaymentGateway.new(:comgate)
      callback_res = gw.provider_gateway
                       .process_callback(params)
      # do not trust payment info from callback body
      gw.check_transaction(callback_res.transaction_id)
    when :go_pay
      # go_pay DO CheckTransaction in process_callback
      Boutique::PaymentGateway.new(:go_pay)
                              .provider_gateway
                              .process_callback(params)
    else
      raise "Uncaptured provider `#{provider}`"
    end
  end

  def initialize(provider = nil)
    @provider = (provider || Boutique.config.payment_gateways[:default]).to_sym
    @provider_gateway = Boutique.config.payment_gateways[@provider]
    raise "Gateway instance not found for :#{@provider}, did you set it in `Boutique.config.payment_gateways`?" unless @provider_gateway
  end

  def check_transaction(transaction_id)
    provider_gateway.check_transaction(transaction_id:)
  end

  def start_transaction(order, options = {})
    provider_gateway.start_transaction(payment_params(order, options))
  end

  def start_recurring_transaction(order, options = {})
    unless order.first_of_subsequent?
      fail "cannot create recurrence for non-recurrent order"
    end

    params = payment_params(order, options)
    params[:payment].deep_merge!({ recurrence: { period: 1 } })

    provider_gateway.start_recurring_transaction(params)
  end

  def repeat_recurring_transaction(order)
    fail "cannot create recurrence for non-recurrent order" unless order.subsequent?

    params = payment_params(order, {})
    params[:payment][:recurrence] = (params[:payment][:recurrence] || {}).merge({
      init_transaction_id: order.original_payment.remote_id,
      period: order.subscription.orders.count
    })

    provider_gateway.repeat_recurring_transaction(params)
  end

  def start_preauthorized_transaction(payment_data)
  end

  def confirm_preauthorized_transaction(payment_data)
  end

  def cancel_preauthorized_transaction(transaction_id)
  end

  def start_verification_transaction(payment_data)
  end

  def refund_transaction(payment, amount)
    payment_data = {
      transaction_id: payment.remote_id,
      payment: {
        currency: payment.order.currency_code,
        amount_in_cents: amount * 100,
        reference_id: payment.order.number,
      }
    }

    provider_gateway.refund_transaction(payment_data)
  end

  def payout_order_refund(order_refund)
    payment = order_refund.order.payments.paid.last
    payment_data = {
      transaction_id: payment.remote_id,
      payment: {
        currency: order_refund.currency_code,
        amount_in_cents: order_refund.total_price_in_cents,
        reference_id: order_refund.document_number,
      }
    }

    provider_gateway.refund_transaction(payment_data)
  end

  def cancel_transaction(transaction_id)
  end

  def allowed_payment_methods(params)
  end

  private
    def payment_params(order, options)
      params = {
        payer: {
          email: order.email,
          phone: nil, # TODO ?
          first_name: order.first_name,
          last_name: order.last_name
        },
        # merchant: { target_shop_account: "12345678/1234" },
        payment: {
          currency: order.currency_code,
          amount_in_cents: order.total_price * 100,
          label: order.to_label,
          reference_id: order.number,
          description: order_description(order),
          method: provider == :comgate ? "ALL" : options[:payment_method],
          product_name: order.model_name.human
        },
        options: {
          country_code: options[:country_of_purchase_code] || "CZ", # show payment methods for Czech Republic
          language_code: options[:language_code] || "cs",
          shop_return_url: options[:return_url],
          callback_url: options[:callback_url],
        },
        items: items_hash(order),
      }

      if address = order.secondary_address || order.primary_address
        params[:payer][:city] =	address.city
        params[:payer][:street_line] =	[address.address_line_1, address.address_line_2].compact.join(", ")
        params[:payer][:postal_code] =  address.zip
        params[:payer][:country_code2] = address.country_code if address.country_code.size == 2
        params[:payer][:country_code3] = address.country_code if address.country_code.size == 3
      end

      if order.line_items.any? { |li| li.subscription? && li.subscription_recurring? }
        params[:payment][:recurrence] = {
          cycle: :on_demand,
          valid_to: Date.new(2099, 12, 31)
        }
      end

      params
    end

    def items_hash(order)
      order.line_items.map do |line_item|
        {
          type: "ITEM",
          name: line_item.title,
          price_in_cents: line_item.price * 100,
          count: line_item.amount,
          vat_rate_percent: line_item.vat_rate_value.to_i,
        }
      end
    end

    def order_description(order)
      "#{order.model_name.human} #{order.to_label}"
    end
end
