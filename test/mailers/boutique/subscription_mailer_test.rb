# frozen_string_literal: true

require "test_helper"

class Boutique::SubscriptionMailerTest < ActionMailer::TestCase
  setup do
    create(:folio_site)
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].execute
  end

  test "ended" do
    user = create(:folio_user, email: "test@test.test")
    subscription = create(:boutique_subscription, user:)

    mail = Boutique::SubscriptionMailer.ended(subscription)
    assert_equal ["test@test.test"], mail.to
  end

  test "failed_payment" do
    user = create(:folio_user, email: "test@test.test")
    subscription = create(:boutique_subscription, user:)

    mail = Boutique::SubscriptionMailer.failed_payment(subscription)
    assert_equal ["test@test.test"], mail.to
  end

  test "will_end_in_a_week" do
    user = create(:folio_user, email: "test@test.test")
    subscription = create(:boutique_subscription, user:)

    mail = Boutique::SubscriptionMailer.will_end_in_a_week(subscription)
    assert_equal ["test@test.test"], mail.to
  end

  test "unpaid" do
    user = create(:folio_user, email: "test@test.test")
    subscription = create(:boutique_subscription, user:)

    mail = Boutique::SubscriptionMailer.unpaid(subscription)
    assert_equal ["test@test.test"], mail.to
  end
end
