# frozen_string_literal: true

class UpdateDefaultNumberOfAllowedUsesForVouchers < ActiveRecord::Migration[7.0]
  def change
    change_column_default :boutique_vouchers, :number_of_allowed_uses, from: nil, to: 1
  end
end
