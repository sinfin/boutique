# frozen_string_literal: true

class Boutique::Subscription < ApplicationRecord
  include Folio::HasAddresses

  EVENT_CALLBACKS = %i[before_cancel
                       after_cancel]

  NOT_CANCELLED_AT_THRESHOLD = 7.days

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

  scope :with_email_notifications_enabled, -> { where(email_notifications: true) }

  scope :active_at, -> (time, include_threshold: true) {
    base = where("(#{table_name}.active_from IS NULL OR #{table_name}.active_from <= ?)", time)

    if include_threshold
      rec = base.recurring
                .where("(#{table_name}.active_until IS NULL OR #{table_name}.active_until >= ?)",
                      time - NOT_CANCELLED_AT_THRESHOLD)

      non_rec = base.non_recurring
                    .where("(#{table_name}.active_until IS NULL OR #{table_name}.active_until >= ?)",
                          time)

      rec.or(non_rec)
    else
      base.where("(#{table_name}.active_until IS NULL OR #{table_name}.active_until >= ?)",
                 time)
    end
  }

  scope :active, -> (include_threshold: true) {
    active_at(Time.current, include_threshold:)
  }

  scope :inactive_at, -> (time, include_threshold: true) {
    base = all
    future = base.where("#{table_name}.active_from > ?", time)

    if include_threshold
      rec = base.recurring
                .where("#{table_name}.active_until < ?", time - NOT_CANCELLED_AT_THRESHOLD)

      non_rec = base.non_recurring
                    .where("#{table_name}.active_until < ?", time)

      future.or(rec).or(non_rec)
    else
      future.or(base.where("#{table_name}.active_until < ?", time))
    end
  }

  scope :inactive, -> (include_threshold: true) {
    inactive_at(Time.current, include_threshold: true)
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

  scope :by_recurrent, -> (bool) {
    case bool
    when true, "true"
      where(recurrent: true)
    when false, "false"
      where(recurrent: false)
    else
      all
    end
  }

  scope :recurring, -> {
    where(recurrent: true, cancelled_at: nil)
  }

  scope :non_recurring, -> {
    where(recurrent: false).or(where.not(cancelled_at: nil))
  }

  scope :expiring_soon, -> {
    recurring.active(include_threshold: false)
             .where(payment_expiration_date: ..Date.today + 7.days)
             .where("#{table_name}.active_until > #{table_name}.payment_expiration_date")
  }

  scope :by_gift, -> (bool) {
    case bool
    when true, "true"
      gifted
    when false, "false"
      not_gifted
    else
      all
    end
  }

  scope :gifted, -> {
    id = Boutique::Order.where(gift: true).select(:boutique_subscription_id)
    where(id:)
  }

  scope :not_gifted, -> {
    id = Boutique::Order.where(gift: false).select(:boutique_subscription_id)
    where(id:)
  }

  scope :by_ordered_at_range, -> (range_str) {
    from, to = range_str.split(/ ?- ?/)

    runner = self

    if from.present?
      from_date_time = DateTime.parse(from)
      runner = runner.where("created_at >= ?", from_date_time)
    end

    if to.present?
      to = "#{to} 23:59" if to.exclude?(":")
      to_date_time = DateTime.parse(to)
      runner = runner.where("created_at <= ?", to_date_time)
    end

    runner
  }

  scope :ordered, -> { order(active_from: :desc) }

  scope :by_product_variant_id, -> (boutique_product_variant_id) {
    where(boutique_product_variant_id:)
  }

  validates :active_from,
            :period,
            presence: true

  validate :validate_primary_address_attributes

  EVENT_CALLBACKS.each do |cb|
    define_method cb do
      # override in main app if needed
    end
  end

  def number
    id
  end

  def email
    user.try(:email)
  end

  def to_label
    [
      "#{self.class.model_name.human} #{number}",
      user.try(:to_label),
    ].compact.join(" – ")
  end

  def active_at?(time)
    if active_from.present? && active_from > time
      return false
    end

    if active_until.present?
      if recurrent? && !cancelled?
        return false if active_until < time - NOT_CANCELLED_AT_THRESHOLD
      else
        return false if active_until < time
      end
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

  def active_now_or_future?
    return true if active_from.present? && active_from > Time.current

    active?
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
    if cancelled?
      errors.add(:base, :already_cancelled)
    end

    if !recurrent?
      errors.add(:base, :non_recurrent)
    end

    before_cancel

    return false if errors.present?

    now = current_time_from_proper_timezone
    update_columns(cancelled_at: now,
                   updated_at: now)

    after_cancel

    true
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

  def self.csv_attribute_names
    %i[id email title price active_from active_until state]
  end

  def csv_attributes(controller = nil)
    self.class.csv_attribute_names.map do |attr|
      csv_attribute(attr)
    end
  end

  def csv_attribute(attr)
    case attr
    when :email
      user&.email
    when :title
      product_variant&.to_console_label
    when :price
      product_variant&.price
    when :state
      self.class.human_attribute_name(active? ? "state/active" : "state/inactive")
    else
      send(attr)
    end
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
#  recurrent_payments_init_id  :string
#  email_notifications         :boolean          default(TRUE)
#  payment_expiration_date     :date
#
# Indexes
#
#  index_boutique_subscriptions_on_active_from                  (active_from)
#  index_boutique_subscriptions_on_active_until                 (active_until)
#  index_boutique_subscriptions_on_boutique_payment_id          (boutique_payment_id)
#  index_boutique_subscriptions_on_boutique_product_variant_id  (boutique_product_variant_id)
#  index_boutique_subscriptions_on_cancelled_at                 (cancelled_at)
#  index_boutique_subscriptions_on_email_notifications          (email_notifications)
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
