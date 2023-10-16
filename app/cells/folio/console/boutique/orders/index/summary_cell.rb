# frozen_string_literal: true

class Folio::Console::Boutique::Orders::Index::SummaryCell < Folio::ConsoleCell
  def show
    render if orders_confirmed.present?
  end

  def orders_confirmed
    return @orders unless @orders.nil?

    date = model[:date].to_date
    @orders_confirmed = model[:scope].where(confirmed_at: date.beginning_of_day..date.end_of_day)
  end

  def total_price_confirmed
    @total_price ||= orders_confirmed.sum { |o| o.total_price.to_f }
  end

  def average_price_confirmed
    total_price_confirmed / orders_confirmed.size
  end

  def orders_paid
    return @orders_paid unless @orders_paid.nil?

    @orders_paid = orders_confirmed.select { |o| o.paid_at.present? }
  end

  def total_price_paid
    @total_price_paid ||= orders_paid.sum { |o| o.total_price.to_f }
  end

  def average_price_paid
    total_price_paid / orders_paid.size
  end
end
