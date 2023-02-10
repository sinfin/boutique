# frozen_string_literal: true

require "test_helper"

class Boutique::InvoicesControllerTest < Boutique::ControllerTest
  test "invoice" do
    order = create(:boutique_order, :confirmed)

    assert_raises(ActiveRecord::RecordNotFound) do
      get invoice_path(order.secret_hash)
    end

    order.pay!

    get invoice_path(order.secret_hash)
    assert_response :ok

    order.cancel!

    get invoice_path(order.secret_hash)
    assert_response :ok
  end
end
