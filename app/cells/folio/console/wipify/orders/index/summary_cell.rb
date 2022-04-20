# frozen_string_literal: true

class Folio::Console::Wipify::Orders::Index::SummaryCell < Folio::ConsoleCell
  def show
    render if orders.present?
  end

  def orders
    return @orders unless @orders.nil?

    date = model[:date].to_date
    @orders = model[:scope].select { |o| o.confirmed_at.try(:to_date) == date }
  end

  def total_price
    @total_price ||= orders.sum { |o| o.total_price.to_f }
  end

  def average_price
    total_price / orders.size
  end
end
