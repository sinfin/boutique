# frozen_string_literal: true

require "test_helper"

class Boutique::OrderRefundTest < ActiveSupport::TestCase

  test "#setup_subscription_refund for subscription order" do
    order = create(:boutique_order, :paid, subscription_product: true)


  end

  test "#setup_subscription_refund for subscription order" do
    order = create(:boutique_order, :paid, subscription_product: false)
  end
end
