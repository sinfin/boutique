# frozen_string_literal: true

class MakeVouchersPublishedByDefault < ActiveRecord::Migration[7.0]
  def change
    change_column_default :boutique_vouchers, :published, from: false, to: true
  end
end
