# frozen_string_literal: true

require "test_helper"

class Boutique::OrderRefundMailerTest < ActionMailer::TestCase
  setup do
    @site = create(:folio_site, system_email: "admin@site.com")
    Rails.application.load_tasks
    Rake::Task["folio:email_templates:idp_seed"].execute
  end

  test "payout by paypal" do
    order = create(:boutique_order, :paid, email: "me@home.com", site: @site)
    assert_equal "CZK", order.currency_code
    order_refund = create(:boutique_order_refund, :paid,
                                                  order:,
                                                  payment_method: "PAYPAL",
                                                  total_price_in_cents: 15800,)

    mail = Boutique::OrderRefundMailer.payout_by_paypal(order_refund)
    mail_text_body = mail.text_part.body.decoded

    assert_equal [@site.system_email], mail.to
    assert_match order_refund.to_label, mail_text_body
    assert_match order_refund.email, mail_text_body
    assert_match "158,00 Kč", mail_text_body
    assert_match "PayPal", mail_text_body
    assert_match "PayPal", mail.subject
  end

  test "payout by voucher" do
    order = create(:boutique_order, :paid, email: "me@home.com", site: @site)
    assert_equal "CZK", order.currency_code
    order_refund = create(:boutique_order_refund, :paid,
                                                  order:,
                                                  payment_method: "VOUCHER",
                                                  total_price_in_cents: 15800,)

    mail = Boutique::OrderRefundMailer.payout_by_voucher(order_refund)
    mail_text_body = mail.text_part.body.decoded

    assert_equal [@site.system_email], mail.to
    assert_match order_refund.to_label, mail_text_body
    assert_match order_refund.email, mail_text_body
    assert_match "158,00 Kč", mail_text_body
    assert_match "Voucher", mail_text_body
    assert_match "Voucher", mail.subject
  end
end
