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
                               foreign_key: :original_order_id,
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
      #   Boutique::GoPay::Api.new.refund_payment(remote_id, order)
      # end
    end
  end

  alias_attribute :timeouted_at, :cancelled_at
  alias_attribute :refunded_at, :cancelled_at

  def payment_method_to_human
    self.class.payment_method_to_human(payment_method) if payment_method.present?
  end

  def self.payment_method_to_human(payment_method_string)
    I18n.t("boutique.go_pay.payment_method.#{payment_method_string}", fallback: payment_method_string.capitalize)
  end
end

# == Schema Information
#
# Table name: boutique_payments
#
#  id                :bigint(8)        not null, primary key
#  boutique_order_id :bigint(8)        not null
#  remote_id         :bigint(8)
#  aasm_state        :string           default("pending")
#  payment_method    :string
#  paid_at           :datetime
#  cancelled_at      :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
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
