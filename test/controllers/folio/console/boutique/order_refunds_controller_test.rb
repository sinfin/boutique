# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::OrderRefundsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Boutique::OrderRefund])

    assert_response :success

    bo_created = create(:boutique_order_refund, :created)
    bo_to_pay = create(:boutique_order_refund, :approved_to_pay)
    bo_paid = create(:boutique_order_refund, :paid)
    bo_cancelled = create(:boutique_order_refund, :cancelled)

    get url_for([:console, Boutique::OrderRefund])

    assert_response :success

    skip "test state tabs"
  end

  test "new" do
    order = create(:boutique_order)
    get url_for([:console, Boutique::OrderRefund, action: :new, order_id: order.id  ])

    assert_response :success

    skip "check prefilled values"
  end

  test "create" do
    params = build(:boutique_order_refund).serializable_hash

    assert_difference("Boutique::OrderRefund.count", 1) do
      post url_for([:console, Boutique::OrderRefund]), params: {
        order_refund: params,
      }
    end
  end

  test "edit" do
    model = create(:boutique_order_refund, :created)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "update" do
    model = create(:boutique_order_refund)
    new_due_date = Date.today + 1.month
    assert_not_equal(new_due_date, model.due_date)

    put url_for([:console, model]), params: {
      order_refund: {
        due_date: due_date.to_s,
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal(new_due_date, model.reload.due_date)
  end

  test "destroy" do
    model = create(:boutique_order_refund)

    delete url_for([:console, model])

    assert_redirected_to url_for([:edit, :console, model])
    assert response.include?("nelze smazat, jen stornovat")
    assert model.class.find(model.id).present?
  end

  test "corrective tax documents" do
    get url_for([:corrective_tax_documents, :console, Boutique::OrderRefund])

    assert_response :success

    bo_refund = create(:boutique_order_refund, :paid)

    get url_for([:corrective_tax_documents, :console, Boutique::OrderRefund])

    assert_response :success
    assert response.body.include?(bo_refund.number)
  end
end
