# frozen_string_literal: true

class Boutique::Delivery::LineItemPackageLink < Boutique::ApplicationRecord
  self.table_name = "boutique_delivery_line_item_package_links"

  belongs_to :package, class_name: "Boutique::Delivery::Package",
                       foreign_key: :package_id,
                       inverse_of: :line_item_package_links
  belongs_to :line_item, class_name: "Boutique::LineItem",
                         foreign_key: :line_item_id,
                         inverse_of: :line_item_package_links

  scope :ordered, -> { order(created_at: :desc, id: :desc) }
end
