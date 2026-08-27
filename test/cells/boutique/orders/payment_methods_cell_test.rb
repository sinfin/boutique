# frozen_string_literal: true

require "test_helper"

# Instantiates the cell directly instead of going through the cell() test
# helper: under Rails 8 that helper builds an ActionController::TestRequest
# with the wrong arity and raises for every cell test in this gem.
class Boutique::Orders::PaymentMethodsCellTest < ActiveSupport::TestCase
  test "payment_button_label defaults to the payment method title" do
    order = create(:boutique_order)
    method = { title: "Platební karta", value: "PAYMENT_CARD" }

    label = Boutique::Orders::PaymentMethodsCell.new(nil).payment_button_label(order, method)

    assert_equal "Platební karta", label
  end

  test "payment_button_label comes from the configured proc" do
    original = Boutique.config.payment_button_label_proc
    Boutique.config.payment_button_label_proc = -> (context:, order:, method:) do
      "Předplatit za #{order.total_price} Kč"
    end

    order = create(:boutique_order)
    method = { title: "Platební karta", value: "PAYMENT_CARD" }

    label = Boutique::Orders::PaymentMethodsCell.new(nil).payment_button_label(order, method)

    assert_equal "Předplatit za #{order.total_price} Kč", label
  ensure
    Boutique.config.payment_button_label_proc = original
  end
end
