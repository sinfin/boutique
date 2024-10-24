# frozen_string_literal: true

require "test_helper"

class Boutique::OrderMailerTest < ActionMailer::TestCase
  setup do
    create(:folio_site)
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].execute

    @user = create(:folio_user, email: "test@test.test")
  end

  test "paid" do
    order = create(:boutique_order, :paid, user: @user)

    mail = Boutique::OrderMailer.paid(order)
    assert_equal ["test@test.test"], mail.to
    assert_match order.number, mail.text_part.body.decoded
  end

  test "paid_subsequent" do
    order = create(:boutique_order, :paid, user: @user)

    mail = Boutique::OrderMailer.paid_subsequent(order)
    assert_equal ["test@test.test"], mail.to
    assert_match order.number, mail.text_part.body.decoded
  end

  test "unpaid_reminder" do
    order = create(:boutique_order, :confirmed, email: "unpaid@test.test")

    mail = Boutique::OrderMailer.unpaid_reminder(order)
    assert_equal ["unpaid@test.test"], mail.to
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

  test "email_for" do
    order = create(:boutique_order, :paid, user: @user)
    order.user.update_columns(email: "john@test.test")

    mail = Boutique::OrderMailer.paid_subsequent(order)
    assert_equal ["john@test.test"], mail.to
  end
end
