# frozen_string_literal: true

class Boutique::ShippingMethod::RegisterPackageJob < ApplicationJob
  queue_as :default

  def perform(order)
    return if order.shipping_method.nil?

    order.shipping_method.register!(order)
  end
end
