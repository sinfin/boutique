# frozen_string_literal: true

class Folio::Console::Boutique::SubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Subscription", through: "Folio::User"

  def cancel
    @subscription.cancel!

    respond_with @subscription, location: respond_with_location
  end

  private
    def subscription_params
      params.require(:subscription)
            .permit(*(@klass.column_names - ["id"]))
    end

    def respond_with_location
      url_for([:console, @user])
    end
end
