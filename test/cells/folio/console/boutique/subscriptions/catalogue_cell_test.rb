# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::Subscriptions::CatalogueCellTest < Folio::Console::CellTest
  test "show" do
    subscription = create(:boutique_subscription)

    html = show(subscription)

    assert html.has_css?(".f-c-b-subscriptions-catalogue")
    assert_not html.has_text?("Trial")
  end

  test "marks a running free trial" do
    subscription = paid_intro_subscription(intro_price: 0, intro_duration_months: 2)

    html = show(subscription)

    assert html.has_text?("Trial do #{I18n.l(subscription.intro_until.to_date, format: :short)}")
  end

  test "marks a running discounted introductory price" do
    subscription = paid_intro_subscription(intro_price: 49, intro_duration_months: 3)

    html = show(subscription)

    assert html.has_text?("Úvodní cena do #{I18n.l(subscription.intro_until.to_date, format: :short)}")
  end

  test "says the trial is over once the introductory period has passed" do
    subscription = paid_intro_subscription(intro_price: 0, intro_duration_months: 1)

    travel 2.months

    html = show(subscription)

    assert html.has_text?("Trial byl do #{I18n.l(subscription.intro_until.to_date, format: :short)}")
  end

  private
    def show(subscription)
      cell("folio/console/boutique/subscriptions/catalogue",
           Boutique::Subscription.where(id: subscription.id)).(:show)
    end

    def paid_intro_subscription(intro_price:, intro_duration_months:)
      product = create(:boutique_product_subscription,
                       digital_only: true,
                       subscription_period: 1,
                       regular_price: 149,
                       intro_enabled: true,
                       intro_price:,
                       intro_duration_months:)

      order = create(:boutique_order, :ready_to_be_confirmed, :with_user,
                                      line_items_count: 0,
                                      digital_only: true)
      order.line_items << build(:boutique_line_item, product:, order:)
      order.save!

      assert order.confirm!, order.errors.full_messages.to_sentence
      order.pay!

      order.subscription.reload
    end
end
