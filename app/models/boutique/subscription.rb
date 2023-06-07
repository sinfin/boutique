# frozen_string_literal: true

class Boutique::Subscription < ApplicationRecord
  include Folio::HasAddresses

  belongs_to :payment, class_name: "Boutique::Payment",
                       foreign_key: :boutique_payment_id,
                       inverse_of: :subscription,
                       optional: true

  belongs_to :product_variant, class_name: "Boutique::ProductVariant",
                               foreign_key: :boutique_product_variant_id,
                               inverse_of: :subscriptions

  has_one :product, through: :product_variant

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

  scope :by_active, -> (bool) {
    case bool
    when true, "true"
      active
    when false, "false"
      inactive
    else
      all
    end
  }

  scope :ordered, -> { order(id: :desc) }

  validates :active_from,
            :period,
            presence: true

  validate :validate_primary_address_attributes

  def number
    id
  end

  def email
    user.email
  end

  def to_label
    [
      "#{self.class.model_name.human} #{number}",
      user.try(:to_label),
    ].compact.join(" – ")
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

  def cancelled?
    cancelled_at?
  end

  def cancel!
    if !recurrent?
      errors.add(:base, :non_recurrent)
      return false
    end

    if cancelled?
      errors.add(:base, :already_cancelled)
      return false
    end

    now = current_time_from_proper_timezone
    update_columns(recurrent: false,
                   cancelled_at: now,
                   updated_at: now)
  end

  def extend!
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
#  recurrent                   :boolean          default(FALSE)
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
#  index_boutique_subscriptions_on_recurrent                    (recurrent)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_payment_id => boutique_payments.id)
#  fk_rails_...  (boutique_product_variant_id => boutique_product_variants.id)
#
