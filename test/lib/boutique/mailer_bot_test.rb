# frozen_string_literal: true

require "test_helper"

class Boutique::MailerBotTest < ActiveSupport::TestCase
  include Boutique::Test::GoPayApiMocker

  def setup
    create(:folio_site)
    @bot = Boutique::MailerBot.new
  end

  test "orders_unpaid_reminder" do
    assert_equal [], @bot.send(:orders_for_unpaid_reminder).map(&:id)

    target = create(:boutique_order, :confirmed, confirmed_at: now - 1.day)
    paid = create(:boutique_order, :confirmed, confirmed_at: now - 1.day, aasm_state: "paid")
    too_old = create(:boutique_order, :confirmed, confirmed_at: now - 25.hours)
    too_fresh = create(:boutique_order, :confirmed, confirmed_at: now - 23.hours)

    assert_equal [target.id], @bot.send(:orders_for_unpaid_reminder).map(&:id)
  end

  private
    def now
      @now ||= Time.current.beginning_of_hour + 30.minutes
    end
end
