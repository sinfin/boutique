# frozen_string_literal: true

class AddMultipleBoolToVouchers < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_vouchers, :multiple, :boolean, default: false

    unless reverting?
      say_with_time("updating records") do
        duplicated_titles = Boutique::Voucher.group(:title).having("COUNT(*) > 1").pluck(:title)
        Boutique::Voucher.where(title: duplicated_titles).update_all(multiple: true)
      end
    end
  end
end
