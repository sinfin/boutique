# frozen_string_literal: true

# == Schema Information
#
# Table name: wipify_product_variants
#
#  id                :bigint           not null, primary key
#  wipify_product_id :bigint           not null
#  title             :string
#  price             :integer          not null
#  master            :boolean          default(FALSE)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
require "test_helper"

module Wipify
  class ProductVariantTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
