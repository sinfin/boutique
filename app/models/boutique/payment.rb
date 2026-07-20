# frozen_string_literal: true

class Boutique::Payment < Boutique::ApplicationRecord
  include AASM
  include Folio::Audited::Model

  audited

  belongs_to :order, class_name: "Boutique::Order",
                     foreign_key: :boutique_order_id,
                     inverse_of: :payments

  has_one :subscription, class_name: "Boutique::Subscription",
                         foreign_key: :boutique_payment_id,
                         inverse_of: :payment

  has_many :subsequent_orders, class_name: "Boutique::Order",
                               foreign_key: :original_payment_id,
                               inverse_of: :original_payment

  scope :ordered, -> { order(id: :desc) }

  validates :remote_id,
            presence: true

  aasm timestamps: true do
    state :pending, initial: true
    state :paid
    state :refunded
    state :cancelled
    state :timeouted

    event :pay do
      transitions from: :pending, to: :paid

      after_commit do
        order.pay!
      rescue AASM::InvalidTransition
        raise "Order #{order.id} is in state #{order.aasm_state} and cannot be paid by payment ##{self.id}!"
      end
    end

    event :cancel do
      transitions from: :pending, to: :cancelled
    end

    event :timeout do
      transitions from: :pending, to: :timeouted
    end

    event :refund do
      transitions from: :paid, to: :refunded

      # before do
      #   payment_gateway.refund_transaction(self, order.total_price)
      # end
    end
  end

  alias_attribute :timeouted_at, :cancelled_at
  alias_attribute :refunded_at, :cancelled_at

  def update_state_from_gateway_check(gateway_result_hash)
    self.with_lock do
      self.order.lock!

      if pending?
        self.payment_method ||= gateway_result_hash[:payment][:method]
        self.transfer_fee ||= gateway_result_hash[:payment][:fee] || 0

        case gateway_result_hash[:state]
        when :paid
          self.card_number = gateway_result_hash[:payment][:card_number]
          self.card_valid_until = gateway_result_hash[:payment][:card_valid]

          pay!
        when :payment_method_chosen
          unless order.waiting_for_offline_payment?
            order.wait_for_offline_payment!
            touch
          end
        when :cancelled
          cancel!
        when :expired, :timeouted
          timeout!
        end

        self.save!
      end
    end
  end

  def amount
    @amount ||= (super || order.total_price)
  end

  def amount_in_cents
    amount * 100
  end

  def payment_gateway
    @payment_gateway ||= if payment_gateway_provider.blank?
      order.payment_gateway
    else
      Boutique::PaymentGateway.new(payment_gateway_provider.to_sym)
    end
  end

  def payment_method_to_human
    self.class.payment_method_to_human(payment_method)
  end

  def card_valid_until_as_date
    return unless card_valid_until

    m, y = card_valid_until.split("/")
    Date.new("20#{y}".to_i, m.to_i) + 1.month
  end

  def self.payment_method_to_human(payment_method_string)
    I18n.t("boutique.payment_gateways.payment_method.#{payment_method_string}", fallback: payment_method_string.capitalize)
  end

  def normalized_payment_method
    # PAYMENT_CARD
    # BANK_ACCOUNT
    # GOOGLE_PAY
    # APPLE_PAY
    # GOPAY
    # PAYPAL
    # PREMIUM_SMS
    # PAYSAFECARD  #PaySafeCard kupón
    # BITCOIN
    # CLICK_TO_PAY

    provider = payment_gateway_provider.to_s
    p_method = payment_method.to_s

    case provider
    when "go_pay"
      case p_method
      when "MPAYMENT"
        "BANK_ACCOUNT"
      when "PRSMS"
        "PREMIUM_SMS"
      when "GPAY"
        "GOOGLE_PAY"
      else
        p_method
      end
    when "comgate"
      if p_method.start_with?("CARD_")
        "PAYMENT_CARD"
      elsif p_method.start_with?("BANK_")
        "BANK_ACCOUNT"
      elsif p_method.start_with?("GOOGLE_")
        "GOOGLE_PAY"
      elsif p_method.start_with?("APPLE_")
        "APPLE_PAY"
      else
        p_method
      end
    when "paypal"
      "PAYPAL"
    when "stripe"
      # the adapter reports PAYMENT_CARD, the hosted checkout page handles
      # the concrete payment method itself
      p_method.presence || "PAYMENT_CARD"
    else
      p_method
    end
  end
end
