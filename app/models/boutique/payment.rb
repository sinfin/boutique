# frozen_string_literal: true

class Boutique::Payment < Boutique::ApplicationRecord
  include AASM

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

      after do
        order.pay!
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
        self.payment_method = gateway_result_hash[:method]

        case gateway_result_hash[:state]
        when :paid
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
      end
    end
  end

  def amount_in_cents
    order.total_price * 100 # TODO: make this attribute, initialized with order.total_price
  end

  def payment_gateway
    order.payment_gateway
  end

  def payment_method_to_human
    self.class.payment_method_to_human(payment_method)
  end

  def self.payment_method_to_human(payment_method_string)
    I18n.t("boutique.payment_gateways.payment_method.#{payment_method_string}", fallback: payment_method_string.capitalize)
  end
end

# == Schema Information
#
# Table name: boutique_payments
#
#  id                       :bigint(8)        not null, primary key
#  boutique_order_id        :bigint(8)        not null
#  remote_id                :string
#  aasm_state               :string           default("pending")
#  payment_method           :string
#  paid_at                  :datetime
#  cancelled_at             :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  payment_gateway_provider :string
#
# Indexes
#
#  index_boutique_payments_on_boutique_order_id  (boutique_order_id)
#  index_boutique_payments_on_remote_id          (remote_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_order_id => boutique_orders.id)
#
