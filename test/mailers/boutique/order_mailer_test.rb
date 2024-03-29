# frozen_string_literal: true

require "test_helper"

class Boutique::OrderMailerTest < ActionMailer::TestCase
  setup do
    create(:folio_site)
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].execute
  end

  test "paid" do
    order = create(:boutique_order, :paid, email: "test@test.test")

    mail = Boutique::OrderMailer.paid(order)
    assert_equal ["test@test.test"], mail.to
    assert_match order.number, mail.text_part.body.decoded
  end

  test "paid_subsequent" do
    order = create(:boutique_order, :paid, email: "test@test.test")

    mail = Boutique::OrderMailer.paid_subsequent(order)
    assert_equal ["test@test.test"], mail.to
    assert_match order.number, mail.text_part.body.decoded
  end

  test "gift_notification" do
    order = create(:boutique_order, :paid, :gift, gift_recipient_email: "test@test.test")

    mail = Boutique::OrderMailer.gift_notification(order)
    assert_equal ["test@test.test"], mail.to
    assert_match order.number, mail.text_part.body.decoded
  end

  test "gift_notification_with_invitation" do
    order = create(:boutique_order, :paid, :gift, gift_recipient_email: "test@test.test")

    mail = Boutique::OrderMailer.gift_notification_with_invitation(order, "INVITATION_TOKEN")
    assert_equal ["test@test.test"], mail.to
    assert_match order.number, mail.text_part.body.decoded
    assert_match "INVITATION_TOKEN", mail.text_part.body.decoded
  end
end
