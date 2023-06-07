# frozen_string_literal: true

class Boutique::ApplicationMailer < Folio::ApplicationMailer
  helper Boutique::PriceHelper
  helper Boutique::SubscriptionHelper
end
