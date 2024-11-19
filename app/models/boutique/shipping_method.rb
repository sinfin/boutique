# frozen_string_literal: true

class Boutique::ShippingMethod < Boutique::ApplicationRecord
  extend Folio::InheritenceBaseNaming

  include Folio::Publishable::Basic
  include Folio::Positionable
  include Folio::RecursiveSubclasses
  include Folio::StiPreload

  has_one :order, class_name: "Boutique::Order",
                  inverse_of: :shipping_method

  has_and_belongs_to_many :products, class_name: "Boutique::Product"

  validates :title,
            :price_cz,
            :price_sk,
            presence: true

  pg_search_scope :by_query,
                  against: %i[title],
                  ignoring: :accents,
                  using: {
                    tsearch: { prefix: true }
                  }

  def self.use_preview_tokens?
    false
  end

  def self.sti_paths
    [
      Boutique::Engine.root.join("app/models/boutique/shipping_method"),
    ]
  end

  def requires_address?
    true
  end

  def requires_pickup_point?
    false
  end

  def tracking_url_for(order)
    return if order.package_tracking_number.blank?

    "https://www.postaonline.cz/trackandtrace/-/zasilka/cislo?parcelNumbers=#{order.package_tracking_number}"
  end

  def price_for(country_code)
    if country_code && country_code.downcase == "sk"
      price_sk
    else
      price_cz
    end
  end
end

# == Schema Information
#
# Table name: boutique_shipping_methods
#
#  id          :bigint(8)        not null, primary key
#  title       :string
#  label       :string
#  description :text
#  price_cz    :integer
#  price_sk    :integer
#  type        :string
#  published   :boolean          default(FALSE)
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_boutique_shipping_methods_on_position   (position)
#  index_boutique_shipping_methods_on_published  (published)
#
