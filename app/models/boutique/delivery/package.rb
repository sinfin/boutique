# frozen_string_literal: true

class Boutique::Delivery::Package < Boutique::ApplicationRecord
  self.table_name = "boutique_delivery_packages"

  include Folio::HasAasmStates
  include StoresStateHistory

  belongs_to :shipment, class_name: "Boutique::Delivery::Shipment", inverse_of: :packages

  has_many :line_item_package_links, -> { ordered },
                          class_name: "Boutique::Delivery::LineItemPackageLink",
                          foreign_key: :package_id,
                          dependent: :destroy,
                          inverse_of: :package

  has_many :line_items, through: :line_item_package_links

  scope :ordered, -> { order(created_at: :desc, id: :desc) }
end
