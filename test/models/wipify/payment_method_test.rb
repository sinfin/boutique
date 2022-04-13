# frozen_string_literal: true

# == Schema Information
#
# Table name: wipify_payment_methods
#
#  id          :bigint           not null, primary key
#  title       :string
#  type        :string
#  description :text
#  price       :string
#  position    :integer
#  published   :boolean          default(FALSE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
require "test_helper"

module Wipify
  class PaymentMethodTest < ActiveSupport::TestCase
    # test "the truth" do
    #   assert true
    # end
  end
end
