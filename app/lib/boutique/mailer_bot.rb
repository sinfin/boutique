# frozen_string_literal: true

class Boutique::MailerBot
  def initialize
  end

  def self.perform_all
    new.all
  end

  def all
    orders_unpaid_reminder
  end

  def orders_unpaid_reminder
    orders_for_unpaid_reminder.each do |order|
      Boutique::OrderMailer.unpaid_reminder(order).deliver_later
    end
  end

  private
    def now
      @now ||= Time.current.beginning_of_hour
    end

    def orders_for_unpaid_reminder
      Boutique::Order.confirmed
                     .where(confirmed_at: (now - 24.hours)..(now - 23.hours))
                     .except_subsequent
    end
end
