# frozen_string_literal: true

class CreateWipifyProducts < ActiveRecord::Migration[7.0]
  def change
    create_table :wipify_products do |t|
      t.string :title, null: false

      t.timestamps
    end
  end
end
