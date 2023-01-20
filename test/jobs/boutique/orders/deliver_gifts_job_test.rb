# frozen_string_literal: true

require "test_helper"

class Boutique::Orders::DeliverGiftsJobTest < ActiveJob::TestCase
  setup do
    @job_instance = Boutique::Orders::DeliverGiftsJob.new
  end

  test "orders_eligable_to_delivery" do
    assert_equal [], @job_instance.send(:orders_ready_for_delivery).map(&:id)

    pending = create(:boutique_order, :gift)
    without_gift = create(:boutique_order, :paid)
    target = create(:boutique_order, :paid, :gift, gift_recipient_notification_scheduled_for: now - 1.day)
    too_early = create(:boutique_order, :paid, :gift, gift_recipient_notification_scheduled_for: now + 1.day)

    assert_equal [target.id], @job_instance.send(:orders_ready_for_delivery).map(&:id)
  end


  private
    def now
      @now ||= Time.current
    end
end
