# frozen_string_literal: true

class Boutique::Delivery::Shipment < Boutique::ApplicationRecord
  self.table_name = "boutique_delivery_shipments"

  include Folio::HasAasmStates
  include StoresStateHistory

  belongs_to :order, class_name: "Boutique::Order", inverse_of: :shipments
  # belongs_to :shipping

  has_many :packages, -> { ordered },
                          class_name: "Boutique::Delivery::Package",
                          foreign_key: :shipment_id,
                          dependent: :destroy,
                          inverse_of: :shipment

  scope :ordered, -> { order(created_at: :desc, id: :desc) }
end

# == Schema Information
#
# Table name: boutique_shipments
#
#  id                            :bigint(8)        not null, primary key
#  aasm_state                    :string
#  branch_id                     :integer
#  address                       :jsonb
#  shipper_tracking_id           :string
#  last_mile_carrier_tracking_id :string
#  tracking_history              :jsonb
#  state_history                 :jsonb
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#
