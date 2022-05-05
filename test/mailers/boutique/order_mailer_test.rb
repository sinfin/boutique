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
end
