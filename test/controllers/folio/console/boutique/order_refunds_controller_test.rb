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
    assert_select ".f-c-catalogue__cell--order a", text: bo_created.order.number, count: 1
    assert_select ".f-c-catalogue__cell--order a", text: bo_to_pay.order.number, count: 1
    assert_select ".f-c-catalogue__cell--order a", text: bo_paid.order.number, count: 1
    assert_select ".f-c-catalogue__cell--order a", text: bo_cancelled.order.number, count: 1

    get url_for([:console, Boutique::OrderRefund, params: { tab: "created" }])

    assert_select ".f-c-catalogue__cell--order a", text: bo_created.order.number, count: 1
    assert_select ".f-c-catalogue__cell--order a", text: bo_to_pay.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_paid.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_cancelled.order.number, count: 0

    get url_for([:console, Boutique::OrderRefund, params: { tab: "approved" }])

    assert_select ".f-c-catalogue__cell--order a", text: bo_created.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_to_pay.order.number, count: 1
    assert_select ".f-c-catalogue__cell--order a", text: bo_paid.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_cancelled.order.number, count: 0

    get url_for([:console, Boutique::OrderRefund, params: { tab: "paid" }])

    assert_select ".f-c-catalogue__cell--order a", text: bo_created.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_to_pay.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_paid.order.number, count: 1
    assert_select ".f-c-catalogue__cell--order a", text: bo_cancelled.order.number, count: 0

    get url_for([:console, Boutique::OrderRefund, params: { tab: "cancelled" }])

    assert_select ".f-c-catalogue__cell--order a", text: bo_created.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_to_pay.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_paid.order.number, count: 0
    assert_select ".f-c-catalogue__cell--order a", text: bo_cancelled.order.number, count: 1
  end

  test "new for subscription order " do
    order = create(:boutique_order, :paid, subscription_product: true)

    get url_for([:console, Boutique::OrderRefund, action: :new, order_id: order.id  ])

    assert_response :success

    assert_select "input[name='order_refund[boutique_order_id]'][type='hidden'][value=\"#{order.id}\"]"
    skip "assert presence of subscription refund fields"
  end

  test "new for non subscription order" do
    order = create(:boutique_order, :paid, subscription_product: false)

    get url_for([:console, Boutique::OrderRefund, action: :new, order_id: order.id  ])

    assert_response :success

    assert_select "input[name='order_refund[boutique_order_id]'][type='hidden'][value=\"#{order.id}\"]"
    skip "assert not presence of subscription refund fields"
  end

  test "create" do
    bor = build(:boutique_order_refund)

    assert_difference("Boutique::OrderRefund.count", 1) do
      post url_for([:console, Boutique::OrderRefund]), params: {
        order_refund: bor.serializable_hash,
      }
    end

    created_bor = Boutique::OrderRefund.last
    assert_redirected_to url_for([:console, created_bor])
    assert_equal(bor.total_price, created_bor.total_price)
    assert_equal(bor.order, created_bor.order)
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
        due_date: new_due_date.to_s,
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal(new_due_date, model.reload.due_date)
  end

  test "destroy" do
    model = create(:boutique_order_refund)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Boutique::OrderRefund])
    assert model.class.find_by(id: model.id).blank?
  end

  test "corrective tax documents" do
    skip
    get url_for([:corrective_tax_documents, :console, Boutique::OrderRefund])

    assert_response :success

    bo_refund = create(:boutique_order_refund, :paid)

    get url_for([:corrective_tax_documents, :console, Boutique::OrderRefund])

    assert_response :success
    assert response.body.include?(bo_refund.number)
  end
end
