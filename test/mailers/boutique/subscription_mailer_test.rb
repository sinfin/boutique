# frozen_string_literal: true

require "test_helper"

class Boutique::SubscriptionMailerTest < ActionMailer::TestCase
  setup do
    create(:folio_site)
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].execute
  end

  test "failure" do
    user = create(:folio_user, email: "test@test.test")
    subscription = create(:boutique_subscription, user:)

    mail = Boutique::SubscriptionMailer.failure(subscription)
    assert_equal ["test@test.test"], mail.to
  end

  test "unpaid" do
    user = create(:folio_user, email: "test@test.test")
    subscription = create(:boutique_subscription, user:)

    mail = Boutique::SubscriptionMailer.unpaid(subscription)
    assert_equal ["test@test.test"], mail.to
  end

  test "will_be_paid_in_a_week" do
    user = create(:folio_user, email: "test@test.test")
    subscription = create(:boutique_subscription, user:)

    mail = Boutique::SubscriptionMailer.will_be_paid_in_a_week(subscription)
    assert_equal ["test@test.test"], mail.to
  end
end
