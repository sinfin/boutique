# frozen_string_literal: true

class Boutique::Product::Subscription < Boutique::Product
  SUBSCRIPTION_FREQUENCIES = {
    monthly: 12,
    bimonthly: 6,
    quarterly: 4,
  }

  validates :subscription_frequency, inclusion: { in: SUBSCRIPTION_FREQUENCIES.keys.map(&:to_s) }

  def subscription_frequency_in_months_per_year
    return if subscription_frequency.nil?

    SUBSCRIPTION_FREQUENCIES[subscription_frequency.to_sym]
  end

  def self.subscription_frequency_options_for_select
    SUBSCRIPTION_FREQUENCIES.keys.map do |value|
      [human_attribute_name("subscription_frequency/#{value}"), value]
    end
  end
end

# == Schema Information
#
# Table name: boutique_products
#
#  id                     :bigint(8)        not null, primary key
#  title                  :string           not null
#  slug                   :string           not null
#  published              :boolean          default(FALSE)
#  published_at           :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  type                   :string
#  variants_count         :integer          default(0)
#  subscription_frequency :string
#
# Indexes
#
#  index_boutique_products_on_published     (published)
#  index_boutique_products_on_published_at  (published_at)
#  index_boutique_products_on_slug          (slug)
#  index_boutique_products_on_type          (type)
#
