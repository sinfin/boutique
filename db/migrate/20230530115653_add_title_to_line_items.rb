# frozen_string_literal: true

class AddTitleToLineItems < ActiveRecord::Migration[7.0]
  def change
    add_column :boutique_line_items, :title, :string

    unless reverting?
      say_with_time "updating records" do
        Boutique::LineItem.includes(product_variant: :product).find_each do |li|
          li.update_columns(title: li.title)
        end
      end
    end
  end
end
