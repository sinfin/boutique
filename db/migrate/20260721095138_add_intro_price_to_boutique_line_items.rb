# frozen_string_literal: true

class AddIntroPriceToBoutiqueLineItems < ActiveRecord::Migration[7.0]
  def change
    # Introductory price snapshots, complementing `unit_price`, `vat_rate_value`
    # and `subscription_period` (see Boutique::LineItem#imprint). On an
    # introductory line item `unit_price` holds the price paid up front; these
    # two columns add how long that price applies and what subsequent orders
    # (see Boutique::Order#subsequent?) are charged afterwards. Only filled in
    # for line items with an introductory price - otherwise they stay nil and
    # recurrences behave as before (a copy of the original price).
    add_column :boutique_line_items, :intro_duration_months, :integer
    add_column :boutique_line_items, :subsequent_unit_price, :integer
  end
end
