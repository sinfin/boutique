# frozen_string_literal: true

class Boutique::Orders::DeliverGiftsJob < Boutique::ApplicationJob
  queue_as :default

  def perform
    orders_ready_for_delivery.find_each do |order|
      order.deliver_gift!
    rescue => error
      Raven.capture_exception(error, extra: { order_id: order.id })
    end
  end

  private
    def orders_ready_for_delivery
      Boutique::Order.except_subsequent
                     .where(aasm_state: %w[paid dispatched])
                     .where(gift: true, gift_recipient_notification_sent_at: nil)
                     .where("gift_recipient_notification_scheduled_for <= ?", Time.current)
    end
end
