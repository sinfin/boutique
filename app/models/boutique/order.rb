# frozen_string_literal: true

class Boutique::Order < Boutique::ApplicationRecord
  include AASM
  include Folio::HasAddresses

  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    inverse_of: :orders,
                    optional: true

  belongs_to :shipping_method, class_name: "Boutique::ShippingMethod",
                               foreign_key: :boutique_shipping_method_id,
                               inverse_of: :orders,
                               optional: true

  belongs_to :payment_method, class_name: "Boutique::PaymentMethod",
                              foreign_key: :boutique_payment_method_id,
                              inverse_of: :orders,
                              optional: true

  has_many :line_items, -> { ordered },
                        class_name: "Boutique::LineItem",
                        foreign_key: :boutique_order_id,
                        counter_cache: :line_items_count,
                        dependent: :destroy,
                        inverse_of: :order

  scope :ordered, -> { order(base_number: :desc, id: :desc) }
  scope :except_pending, -> { where.not(aasm_state: "pending") }

  scope :by_state, -> (state) { where(aasm_state: state) }

  validates :email,
            :base_number,
            :number,
            :line_items,
            # :payment_method,
            # :shipping_method,
            presence: true,
            unless: :pending?

  validates :primary_address,
            presence: true,
            if: :requires_address_and_not_pending?

  aasm timestamps: true do
    state :pending, initial: true
    state :confirmed, color: "red"
    state :paid, color: "yellow"
    state :dispatched, color: "green"
    state :cancelled, color: "dark"

    states = Boutique::Order.aasm.states.map(&:name)

    event :confirm do
      transitions from: :pending, to: :confirmed

      before do
        set_numbers
        imprint_prices
      end

      after_commit do
        Boutique::OrderMailer.confirmed(self).deliver_later
      end
    end

    event :pay do
      transitions from: :confirmed, to: :paid

      after_commit do
        Boutique::OrderMailer.paid(self).deliver_later
      end
    end

    event :dispatch do
      transitions from: :paid, to: :dispatched

      after_commit do
        Boutique::OrderMailer.dispatched(self).deliver_later
      end
    end

    event :cancel do
      transitions from: states.without(:cancelled), to: :cancelled
    end

    event :revert_cancelation do
      transitions from: :cancelled, to: :dispatched, guard: :dispatched_at?
      transitions from: :cancelled, to: :paid, guard: :paid_at?
      transitions from: :cancelled, to: :confirmed, guard: :confirmed_at?
      transitions from: :cancelled, to: :pending

      before { self.cancelled_at = nil }
    end
  end


  def to_label
    [
      number,
      user.try(:full_name) || email
    ].compact.join(" - ")
  end

  def line_items_price
    super || line_items.sum(&:price)
  end

  def shipping_method_price
    super || shipping_method.try(:price)
  end

  def payment_method_price
    super || payment_method.try(:price)
  end

  def total_price
    super || [
      line_items_price,
      shipping_method_price.to_i,
      payment_method_price.to_i,
    ].sum
  end

  def add_line_item(product_variant, amount: 1)
    Boutique::Order.transaction do
      if line_item = line_items.all.find { |li| li.boutique_product_variant_id == product_variant.id }
        line_item.amount += amount
        line_item.save!
      else
        line_items.build(product_variant:,
                         amount:)
      end

      save!
    end
  end

  private
    def set_numbers
      return if base_number.present?

      year_prefix = Time.zone.now.year.to_s.last(2)
      self.base_number = get_next_base_number

      # format: 2200001, 2200002 ... 2309998, 2309999
      self.number = year_prefix + base_number.to_s.rjust(5, "0")
    end

    def get_next_base_number
      ActiveRecord::Base.nextval("boutique_orders_base_number_seq")
    end

    def imprint_prices
      line_items.each { |li| li.imprint_unit_price! }

      self.line_items_price = line_items_price
      self.payment_method_price = payment_method_price.to_i
      self.shipping_method_price = shipping_method_price.to_i
      self.total_price = total_price
    end

    def requires_address?
      true
    end

    def requires_address_and_not_pending?
      requires_address? && !pending?
    end
end

# == Schema Information
#
# Table name: boutique_orders
#
#  id                          :bigint(8)        not null, primary key
#  folio_user_id               :bigint(8)
#  web_session_id              :string
#  base_number                 :integer
#  number                      :string
#  email                       :string
#  aasm_state                  :string           default("pending")
#  line_items_count            :integer          default(0)
#  line_items_price            :integer
#  shipping_method_price       :integer
#  payment_method_price        :integer
#  total_price                 :integer
#  primary_address_id          :bigint(8)
#  secondary_address_id        :bigint(8)
#  use_secondary_address       :boolean          default(FALSE)
#  confirmed_at                :datetime
#  paid_at                     :datetime
#  dispatched_at               :datetime
#  cancelled_at                :datetime
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  boutique_shipping_method_id :bigint(8)
#  boutique_payment_method_id  :bigint(8)
#
# Indexes
#
#  index_boutique_orders_on_boutique_payment_method_id   (boutique_payment_method_id)
#  index_boutique_orders_on_boutique_shipping_method_id  (boutique_shipping_method_id)
#  index_boutique_orders_on_folio_user_id                (folio_user_id)
#  index_boutique_orders_on_number                       (number)
#  index_boutique_orders_on_web_session_id               (web_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_payment_method_id => boutique_payment_methods.id)
#  fk_rails_...  (boutique_shipping_method_id => boutique_shipping_methods.id)
#  fk_rails_...  (folio_user_id => folio_users.id)
#
