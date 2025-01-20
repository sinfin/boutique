# frozen_string_literal: true

class Boutique::Orders::PendingPaymentsCheckJob < Boutique::ApplicationJob
  queue_as :default

  def perform
    payments_to_check.each do |payment|
      payment_result = Boutique::PaymentGateway.new(payment.payment_gateway_provider.to_sym)
                                               .check_transaction(payment.remote_id)
      payment.update_state_from_gateway_check(payment_result.hash)
    rescue => error
      if Object.const_defined?("Sentry")
        ::Sentry.capture_exception(error, extra: { payment_id: payment.id })
      else
        ::Raven.capture_exception(error, extra: { payment_id: payment.id })
      end

    end
  end

  def payments_to_check
    Boutique::Payment.pending
                     .where("updated_at < ? ", 1.hour.ago)
  end
end
