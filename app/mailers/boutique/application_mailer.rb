# frozen_string_literal: true

class Boutique::ApplicationMailer < Folio::ApplicationMailer
  helper Boutique::SubscriptionHelper

  private
    def email_template_data_defaults(model)
      Boutique.config.email_template_data_defaults_proc.call(model)
    end
end
