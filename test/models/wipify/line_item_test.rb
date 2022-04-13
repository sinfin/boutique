# frozen_string_literal: true

# == Schema Information
#
# Table name: wipify_line_items
#
#  id                        :bigint           not null, primary key
#  wipify_order_id           :bigint           not null
#  price                     :integer
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  wipify_product_variant_id :bigint           not null
#
require "test_helper"

module Wipify
  class LineItemTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
