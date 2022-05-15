# frozen_string_literal: true

require "test_helper"

class Boutique::SubscripionTest < ActiveSupport::TestCase
  test "active" do
    assert_equal [], Boutique::Subscription.active.ids

    yet_not_active = create(:boutique_subscription, active_from: 1.month.from_now)
    active = create(:boutique_subscription, active_until: 1.month.from_now)
    expired = create(:boutique_subscription, active_until: 1.day.ago)

    assert_equal [active.id].sort, Boutique::Subscription.active.ids.sort
    assert_not yet_not_active.active?
    assert active.active?
    assert_not expired.active?
  end
end
