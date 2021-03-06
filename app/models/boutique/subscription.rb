# frozen_string_literal: true

class Boutique::Subscription < ApplicationRecord
  belongs_to :payment, class_name: "Boutique::Payment",
                       foreign_key: :boutique_payment_id,
                       inverse_of: :subscription

  belongs_to :product_variant, class_name: "Boutique::ProductVariant",
                               foreign_key: :boutique_product_variant_id,
                               inverse_of: :subscriptions

  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    inverse_of: :subscriptions

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

  scope :ordered, -> { order(active_from: :desc) }

  validates :active_from,
            :active_until,
            :period,
            presence: true

  def active_at?(time)
    if active_from.present? && active_from >= time
      return false
    end

    if active_until.present? && active_until <= time
      return false
    end

    true
  end

  def active?
    active_at?(Time.current)
  end

  def unactive?
    !active?
  end

  def current_order
    orders.first
  end

  def cancel!
    return false if cancelled_at?

    now = current_time_from_proper_timezone
    update_columns(cancelled_at: now,
                   updated_at: now)
    true
  end

  def prolong!
    update!(active_until: active_until + period.months)
  end
end

# == Schema Information
#
# Table name: boutique_subscriptions
#
#  id                          :bigint(8)        not null, primary key
#  boutique_payment_id         :bigint(8)
#  boutique_product_variant_id :bigint(8)        not null
#  folio_user_id               :bigint(8)        not null
#  period                      :integer          default(12)
#  active_from                 :datetime
#  active_until                :datetime
#  cancelled_at                :datetime
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#
# Indexes
#
#  index_boutique_subscriptions_on_active_from                  (active_from)
#  index_boutique_subscriptions_on_active_until                 (active_until)
#  index_boutique_subscriptions_on_boutique_payment_id          (boutique_payment_id)
#  index_boutique_subscriptions_on_boutique_product_variant_id  (boutique_product_variant_id)
#  index_boutique_subscriptions_on_cancelled_at                 (cancelled_at)
#  index_boutique_subscriptions_on_folio_user_id                (folio_user_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_payment_id => boutique_payments.id)
#  fk_rails_...  (boutique_product_variant_id => boutique_product_variants.id)
#  fk_rails_...  (folio_user_id => folio_users.id)
#
