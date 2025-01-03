# frozen_string_literal: true

class Boutique::Orders::DeliverGiftsJob < Boutique::ApplicationJob
  queue_as :default

  def perform
    if Rails.cache.read("boutique:orders:deliver-gifts").present?
      puts "Skipping Boutique::Orders::DeliverGiftsJob as boutique:orders:deliver-gifts is present in cache"
    else
      Rails.cache.write("boutique:orders:deliver-gifts", "1", expires_in: 14.minutes)

      orders_ready_for_delivery.find_each do |order|
        order.deliver_gift!
      rescue => error
        Raven.capture_exception(error, extra: { order_id: order.id })
      end
    end
  ensure
    Rails.cache.delete("boutique:orders:deliver-gifts")
  end

  private
    def orders_ready_for_delivery
      Boutique::Order.except_subsequent
                     .where(aasm_state: %w[paid dispatched delivered])
                     .where(gift: true, gift_recipient_notification_sent_at: nil)
                     .where("gift_recipient_notification_scheduled_for <= ?", Time.current)
                     .includes(:gift_recipient,
                               :primary_address,
                               :site,
                               line_items: :product)
    end
end
