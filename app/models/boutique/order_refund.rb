class Boutique::OrderRefund < Boutique::ApplicationRecord
  include Folio::HasAasmStates


  belongs_to :order, class_name: "Boutique::Order", foreign_key: :boutique_order_id, inverse_of: :refunds

  delegate :user, :currency_code, to: :order
end

# == Schema Information
#
# Table name: boutique_order_refunds
#
#  id                     :bigint(8)        not null, primary key
#  number                 :string
#  issue_date             :date
#  due_date               :date
#  date_of_taxable_supply :date
#  boutique_order_id      :bigint(8)        not null
#  reason                 :text
#  total_price_in_cents   :integer
#  aasm_state             :string
#  paid_at                :datetime
#  cancelled_at           :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_boutique_order_refunds_on_boutique_order_id  (boutique_order_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_order_id => boutique_orders.id)
#
