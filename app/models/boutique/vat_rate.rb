# frozen_string_literal: true

class Boutique::VatRate < Boutique::ApplicationRecord
  has_many :products, class_name: "Boutique::Product",
                      foreign_key: :boutique_vat_rate_id,
                      dependent: :restrict_with_error,
                      inverse_of: :vat_rate

  scope :ordered, -> { order(value: :desc) }

  pg_search_scope :by_query,
                  against: :title,
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  validates :title,
            :value,
            presence: true

  def self.default
    where(default: true).first
  end
end

# == Schema Information
#
# Table name: boutique_vat_rates
#
#  id         :bigint(8)        not null, primary key
#  value      :integer
#  title      :string
#  default    :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_boutique_vat_rates_on_value  (value)
#
