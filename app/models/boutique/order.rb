# frozen_string_literal: true

class Boutique::Order < Boutique::ApplicationRecord
  include AASM
  include Folio::HasAddresses
  include Folio::HasSecretHash

  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    inverse_of: :orders,
                    optional: true

  belongs_to :subscription, class_name: "Boutique::Subscription",
                            foreign_key: :boutique_subscription_id,
                            inverse_of: :orders,
                            optional: true

  belongs_to :original_payment, class_name: "Boutique::Payment",
                                foreign_key: :original_payment_id,
                                inverse_of: :subsequent_orders,
                                optional: true

  has_many :line_items, -> { ordered },
                        class_name: "Boutique::LineItem",
                        foreign_key: :boutique_order_id,
                        counter_cache: :line_items_count,
                        dependent: :destroy,
                        inverse_of: :order

  accepts_nested_attributes_for :line_items

  has_many :payments, -> { ordered },
                      class_name: "Boutique::Payment",
                      foreign_key: :boutique_order_id,
                      dependent: :destroy,
                      inverse_of: :order

  has_one :paid_payment, -> { paid },
                         class_name: "Boutique::Payment",
                         foreign_key: :boutique_order_id

  scope :ordered, -> { order(base_number: :desc, id: :desc) }
  scope :except_pending, -> { where.not(aasm_state: "pending") }
  scope :except_subsequent, -> { where(original_payment_id: nil) }

  scope :by_state, -> (state) { where(aasm_state: state) }

  validates :first_name,
            :last_name,
            :base_number,
            :number,
            :line_items,
            presence: true,
            unless: :pending?

  validates :email,
            format: { with: Folio::EMAIL_REGEXP },
            unless: :pending?

  validate :validate_primary_address
  validate :validate_email_not_already_registered, unless: :pending?

  validates :primary_address,
            presence: true,
            if: :requires_address_and_not_pending?

  aasm timestamps: true do
    state :pending, initial: true
    state :confirmed, color: "red"
    state :waiting_for_offline_payment, color: "red"
    state :paid, color: "yellow"
    state :dispatched, color: "green"
    state :cancelled, color: "dark"

    states = Boutique::Order.aasm.states.map(&:name)

    event :confirm, private: true do
      transitions from: :pending, to: :confirmed

      before do
        set_numbers
        imprint_prices

        self.email ||= user.try(:email)
      end

      after_commit do
        charge_recurrent_payment! if subsequent?
      end
    end

    event :wait_for_offline_payment, private: true do
      transitions from: :confirmed, to: :waiting_for_offline_payment

      after do
        invite_user!
      end
    end

    event :pay, private: true do
      transitions from: %i[confirmed waiting_for_offline_payment], to: :paid

      before do
        unless subsequent?
          set_up_subscription!
        end
      end

      after do
        if subsequent?
          subscription.prolong!
        else
          invite_user!
        end
      end

      after_commit do
        if subsequent?
          Boutique::OrderMailer.paid_subsequent(self).deliver_later
        else
          Boutique::OrderMailer.paid(self).deliver_later
        end
      end
    end

    event :dispatch do
      transitions from: :paid, to: :dispatched
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

  def self.secret_hash_length
    16
  end

  def to_label
    [
      number,
      user.try(:full_name) || email
    ].compact.join(" – ")
  end

  def line_items_price
    super || line_items.sum(&:price)
  end

  def total_price
    super || [
      line_items_price,
    ].sum
  end

  def unpaid?
    !paid_at?
  end

  def add_line_item!(product_variant, amount: 1)
    Boutique::Order.transaction do
      if ::Boutique.config.use_cart_in_orders
        if line_item = line_items.all.find { |li| li.boutique_product_variant_id == product_variant.id }
          line_item.amount += amount
          line_item.save!
        else
          line_items.build(product_variant:,
                           amount:)
        end
      else
        # TODO: add line item count validation
        if line_item = line_items.first
          line_item.update!(product_variant:,
                            amount:)
        else
          line_items.build(product_variant:,
                           amount:)
        end
      end

      save!
    end
  end

  def digital_only?
    line_items.all?(&:digital_only?)
  end

  def subsequent?
    original_payment_id?
  end

  def checkout_title
    line_items.first.try(:product_variant).try(:title).presence || self.class.model_name.human
  end

  def charge_recurrent_payment!
    return unless confirmed? && subsequent?

    begin
      payment = Boutique::GoPay::Api.new.create_recurrent_payment(self)
      payments.create!(remote_id: payment["id"],
                       payment_method: payment["payment_instrument"])
    rescue GoPay::Error => error
      if error.body["errors"].any? { |e| e["error_code"] == 342 }
        # 342: PAYMENT_RECURRENCE_STOPPED
        # cancel subscription if recurrence was stopped in GoPay admin
        subscription.cancel!
      else
        raise error
      end
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

    def set_up_subscription!
      li = line_items.select(&:subscription?)

      return if li.empty?

      fail "multiple subscriptions in one order are not implemented" if li.size > 1

      line_item = li.first
      period = 12
      active_from = line_item.subscription_starts_at || current_time_from_proper_timezone
      cancelled_at = active_from unless line_item.subscription_recurring?

      build_subscription(payment: paid_payment,
                         product_variant: line_item.product_variant,
                         user:,
                         period:,
                         active_from:,
                         active_until: active_from + period.months,
                         cancelled_at:)
    end

    def get_next_base_number
      ActiveRecord::Base.nextval("boutique_orders_base_number_seq")
    end

    def imprint_prices
      line_items.each { |li| li.imprint_unit_price! }

      self.line_items_price = line_items_price
      self.total_price = total_price
    end

    def invite_user!
      return unless user.nil?

      self.user = Folio::User.invite!(email:,
                                      first_name:,
                                      last_name:)
      update_columns(folio_user_id: user.id)
    end

    def requires_address?
      !digital_only?
    end

    def requires_address_and_not_pending?
      requires_address? && !pending?
    end

    def validate_primary_address
      return unless requires_address_and_not_pending?
      if primary_address.blank?
        build_primary_address
        primary_address.valid?
        errors.add(:primary_address, :blank)
      end
    end

    def validate_email_not_already_registered
      return if email.nil?
      return if user.present?

      if Folio::User.where(email:).exists?
        errors.add(:email, :already_registered)
      end
    end
end
# == Schema Information
#
# Table name: boutique_orders
#
#  id                       :bigint(8)        not null, primary key
#  folio_user_id            :bigint(8)
#  web_session_id           :string
#  base_number              :integer
#  number                   :string
#  secret_hash              :string
#  email                    :string
#  first_name               :string
#  last_name                :string
#  aasm_state               :string           default("pending")
#  line_items_count         :integer          default(0)
#  line_items_price         :integer
#  total_price              :integer
#  primary_address_id       :bigint(8)
#  secondary_address_id     :bigint(8)
#  use_secondary_address    :boolean          default(FALSE)
#  confirmed_at             :datetime
#  paid_at                  :datetime
#  dispatched_at            :datetime
#  cancelled_at             :datetime
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  boutique_subscription_id :bigint(8)
#  original_payment_id      :bigint(8)
#
# Indexes
#
#  index_boutique_orders_on_boutique_subscription_id  (boutique_subscription_id)
#  index_boutique_orders_on_folio_user_id             (folio_user_id)
#  index_boutique_orders_on_number                    (number)
#  index_boutique_orders_on_original_payment_id       (original_payment_id)
#  index_boutique_orders_on_web_session_id            (web_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_subscription_id => boutique_subscriptions.id)
#  fk_rails_...  (folio_user_id => folio_users.id)
#
