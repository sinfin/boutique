# frozen_string_literal: true

class Boutique::Subscription < ApplicationRecord
  include Folio::HasAddresses

  audited only: %i[active_from active_until]

  belongs_to :payment, class_name: "Boutique::Payment",
                       foreign_key: :boutique_payment_id,
                       inverse_of: :subscription,
                       optional: true

  belongs_to :product_variant, class_name: "Boutique::ProductVariant",
                               foreign_key: :boutique_product_variant_id,
                               inverse_of: :subscriptions

  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    inverse_of: :subscriptions,
                    optional: true

  belongs_to :payer, class_name: "Folio::User",
                     foreign_key: :payer_id,
                     inverse_of: :paid_for_subscriptions,
                     optional: true

  has_many :orders, -> { ordered },
                    class_name: "Boutique::Order",
                    foreign_key: :boutique_subscription_id,
                    dependent: :nullify,
                    inverse_of: :subscription

  scope :active_at, -> (time) {
    where("(#{table_name}.active_from IS NULL OR #{table_name}.active_from <= ?) AND "\
          "(#{table_name}.active_until IS NULL OR #{table_name}.active_until >= ?)",
          time,
          time)
  }

  scope :active, -> {
    active_at(Time.current)
  }

  scope :inactive_at, -> (time) {
    where("(#{table_name}.active_from IS NOT NULL AND #{table_name}.active_from > ?) OR "\
          "(#{table_name}.active_until IS NOT NULL AND #{table_name}.active_until < ?)",
          time,
          time)
  }

  scope :inactive, -> {
    inactive_at(Time.current)
  }

  scope :ordered, -> { order(active_until: :desc, active_from: :desc) }

  validates :active_from,
            # :active_until,
            :period,
            presence: true

  # validates :payment,
  #           presence: true,
  #           unless: :cancelled?

  validate :validate_primary_address_attributes

  def to_label
    [
      product_variant.title || product_variant.product.to_label,
      ("(#{active_range})" if active_from.present?),
    ].compact
     .join(" ")
  end

  def active_at?(time)
    if active_from.present? && active_from >= time
      return false
    end

    if active_until.present? && active_until <= time
      return false
    end

    true
  end

  def active_range
    if active_from.present?
      [
        active_from,
        active_until
      ].filter_map { |a| I18n.l(a, format: :as_date) if a }
       .join(" – ")
    end
  end

  def active?
    active_at?(Time.current)
  end

  def unactive?
    !active?
  end

  def expired_at?(time)
    active_until.present? && active_until <= time
  end

  def expired?
    expired_at?(Time.current)
  end

  def current_order
    orders.first
  end

  def original_order
    orders.last
  end

  # Pricing is snapshotted on the line item of the order the subscription
  # started with, so that later changes of the product do not affect it.
  def original_line_item
    @original_line_item ||= original_order&.line_items&.detect(&:subscription?)
  end

  # End of the introductory period, nil when there was none. Derived from
  # active_from on purpose - whenever active_from is shifted, this shifts too.
  def intro_until
    return if active_from.nil?
    return if original_line_item.nil? || original_line_item.intro_duration_months.nil?

    active_from + original_line_item.intro_duration_months.months
  end

  def intro_active?
    intro_until.present? && intro_until > Time.current
  end

  # Unit price for the period that is about to start - that one begins at
  # active_until. Returns nil for subscriptions without a snapshot, those keep
  # copying the price of the original line item (see Boutique::SubscriptionBot).
  def price_for_next_period
    return if original_line_item.nil?

    # a free introductory block is paid for in one go, there is no second
    # period to charge zero for - never renew for free
    return original_line_item.subsequent_unit_price if original_line_item.free_intro?

    if intro_until.present? && active_until.present? && active_until < intro_until
      original_line_item.unit_price
    else
      original_line_item.subsequent_unit_price
    end
  end

  def cancelled?
    cancelled_at?
  end

  def cancel!
    if cancelled_at.nil?
      update(cancelled_at: current_time_from_proper_timezone)
    else
      errors.add(:base, :already_cancelled)
      false
    end
  end

  def prolong!
    update!(active_until: active_until + period.months)
  end

  def should_validate_address?
    return false if product_variant.nil?

    !product_variant.product.digital_only?
  end

  def use_secondary_address
    false
  end

  def self.primary_address_fields_layout
    [
      :name,
      { address_line_1: 8, address_line_2: 4 },
      { city: 7, zip: 5 },
      :country_code,
      :phone,
    ]
  end

  def self.console_additional_index_action(record, context)
    nil
  end

  private
    def validate_primary_address_attributes
      return if primary_address.nil?

      primary_address.errors.add(:name, :blank) if primary_address.name.blank?
    end
end

# == Schema Information
#
# Table name: boutique_subscriptions
#
#  id                          :bigint(8)        not null, primary key
#  boutique_payment_id         :bigint(8)
#  boutique_product_variant_id :bigint(8)        not null
#  folio_user_id               :bigint(8)
#  period                      :integer          default(12)
#  active_from                 :datetime
#  active_until                :datetime
#  cancelled_at                :datetime
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  primary_address_id          :bigint(8)
#  payer_id                    :bigint(8)
#
# Indexes
#
#  index_boutique_subscriptions_on_active_from                  (active_from)
#  index_boutique_subscriptions_on_active_until                 (active_until)
#  index_boutique_subscriptions_on_boutique_payment_id          (boutique_payment_id)
#  index_boutique_subscriptions_on_boutique_product_variant_id  (boutique_product_variant_id)
#  index_boutique_subscriptions_on_cancelled_at                 (cancelled_at)
#  index_boutique_subscriptions_on_folio_user_id                (folio_user_id)
#  index_boutique_subscriptions_on_payer_id                     (payer_id)
#  index_boutique_subscriptions_on_primary_address_id           (primary_address_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_payment_id => boutique_payments.id)
#  fk_rails_...  (boutique_product_variant_id => boutique_product_variants.id)
#
