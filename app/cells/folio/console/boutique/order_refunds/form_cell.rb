# frozen_string_literal: true

class Folio::Console::Boutique::OrderRefunds::FormCell < Folio::ConsoleCell
  include Folio::Console::TabsHelper
  include ActionView::Helpers::NumberHelper

  def f
    model
  end

  def order_refund
    model.object
  end

  def order
    order_refund.order
  end

  def allowed_payment_method_options
    Boutique::OrderRefund.payment_method_options.select { |label, key| order_refund.allowed_payment_methods.include?(key) }
  end

  def allowed_date_ranges
    dr = order_refund.subscription_date_range
    dr.present? ? { min_date: dr.begin.to_s, max_date: dr.end.to_s } : {}
  end
end
