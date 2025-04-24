# frozen_string_literal: true

class Boutique::Product::Subscription < Boutique::Product
  SUBSCRIPTION_FREQUENCIES = {
    none: nil,
    monthly: 1,
    bimonthly: 2,
    quarterly: 3,
    semiannual: 6,
  }

  validates :subscription_frequency, inclusion: { in: SUBSCRIPTION_FREQUENCIES.keys.map(&:to_s) }

  def subscription_recurrent_payment_enabled?
    !subscription_recurrent_payment_disabled?
  end

  def current_issue
    issue_at(Date.today)
  end

  def upcoming_issue
    issue_at(Date.today + subscription_frequency_in_months_per_issue.months)
  end

  def issue_at(date)
    return unless has_subscription_frequency?

    if subscription_frequency_in_months_per_issue == 1
      number = month = date.month
    else
      number = (date.month.to_f / subscription_frequency_in_months_per_issue).ceil
      month = (number - 1) * subscription_frequency_in_months_per_issue + 1
    end

    {
      number:,
      month:,
      year: date.year,
    }
  end

  def current_and_upcoming_issues(years = 1)
    return [] unless has_subscription_frequency?

    start = Date.today
    per_year = 12 / subscription_frequency_in_months_per_issue

    (years * per_year).times.map do |i|
      date = start + (i * subscription_frequency_in_months_per_issue).months
      issue_at(date)
    end
  end

  def subscription_frequency_in_months_per_issue
    return unless has_subscription_frequency?

    SUBSCRIPTION_FREQUENCIES[subscription_frequency.to_sym]
  end

  def subscription_frequency_in_issues_per_year
    return unless has_subscription_frequency?

    12 / subscription_frequency_in_months_per_issue
  end

  def has_subscription_frequency?
    subscription_frequency != "none"
  end

  def self.subscription_frequency_options_for_select
    SUBSCRIPTION_FREQUENCIES.keys.map do |value|
      [human_attribute_name("subscription_frequency/#{value}"), value]
    end
  end

  def to_line_item_full_label(html_context: nil, product_variant: nil, line_item: nil, order: nil)
    if line_item&.subscription_starts_at
      # FIXME: quick hack - line item labels should be refactored
      if line_item&.subscription_frequency
        current_subscription_frequency = subscription_frequency
        self.subscription_frequency = line_item.subscription_frequency
      end

      from = issue_at(line_item&.subscription_starts_at)
      to = issue_at(line_item&.subscription_starts_at + 11.months)

      self.subscription_frequency = current_subscription_frequency if current_subscription_frequency

      return super unless from && to

      "#{title} (#{from[:number]}/#{from[:year]} –⁠ #{to[:number]}/#{to[:year]})"
    else
      super
    end
  end
end

# == Schema Information
#
# Table name: boutique_products
#
#  id                                      :bigint(8)        not null, primary key
#  title                                   :string           not null
#  slug                                    :string           not null
#  published                               :boolean          default(FALSE)
#  published_at                            :datetime
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  type                                    :string
#  variants_count                          :integer          default(0)
#  subscription_frequency                  :string
#  boutique_vat_rate_id                    :bigint(8)        not null
#  site_id                                 :bigint(8)
#  shipping_info                           :text
#  digital_only                            :boolean          default(FALSE)
#  subscription_recurrent_payment_disabled :boolean          default(FALSE)
#  preview_token                           :string
#  code                                    :string(32)
#  checkout_sidebar_content                :text
#  description                             :text
#  subscription_period                     :integer          default(12)
#  regular_price                           :integer
#  discounted_price                        :integer
#  discounted_from                         :datetime
#  discounted_until                        :datetime
#  best_offer                              :boolean          default(FALSE)
#  variant_type_title                      :string
#
# Indexes
#
#  index_boutique_products_on_boutique_vat_rate_id  (boutique_vat_rate_id)
#  index_boutique_products_on_published             (published)
#  index_boutique_products_on_published_at          (published_at)
#  index_boutique_products_on_site_id               (site_id)
#  index_boutique_products_on_slug                  (slug)
#  index_boutique_products_on_type                  (type)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_vat_rate_id => boutique_vat_rates.id)
#
