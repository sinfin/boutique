# frozen_string_literal: true

require "test_helper"

class Boutique::SubscripionTest < ActiveSupport::TestCase
  test "active" do
    assert_equal [], Boutique::Subscription.active.ids

    yet_not_active = create(:boutique_subscription, active_from: 1.month.from_now, recurrent: true)
    active = create(:boutique_subscription, active_until: 1.month.from_now, recurrent: true)
    expired_but_in_threshold = create(:boutique_subscription, active_until: 1.day.ago, recurrent: true)
    expired = create(:boutique_subscription, active_until: 8.day.ago, recurrent: true)

    assert_equal [active.id, expired_but_in_threshold.id].sort, Boutique::Subscription.active.ids.sort
    assert_equal [yet_not_active.id, expired.id].sort, Boutique::Subscription.inactive.ids.sort
    assert_not yet_not_active.active?
    assert active.active?
    assert expired_but_in_threshold.active?
    assert_not expired.active?

    Boutique::Subscription.update_all(recurrent: false)

    assert_equal [active.id].sort, Boutique::Subscription.active.ids.sort
    assert_equal [yet_not_active.id, expired_but_in_threshold.id, expired.id].sort, Boutique::Subscription.inactive.ids.sort
    assert_not yet_not_active.reload.active?
    assert active.reload.active?
    assert_not expired_but_in_threshold.reload.active?
    assert_not expired.reload.active?
  end

  test "cancel" do
    subscription = create(:boutique_subscription, recurrent: true)

    assert subscription.cancel!
    assert subscription.cancelled?

    assert_not subscription.cancel!
    assert subscription.errors.added?(:base, :already_cancelled)

    subscription = create(:boutique_subscription, recurrent: false)

    assert_not subscription.cancel!
    assert subscription.errors.added?(:base, :non_recurrent)

    subscription = create(:boutique_subscription, recurrent: true)
    subscription.instance_eval do
      def before_cancel
        errors.add(:base, :foo)
      end
    end

    assert_not subscription.cancel!
    assert subscription.errors.added?(:base, :foo)
  end
end
