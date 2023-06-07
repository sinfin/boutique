# frozen_string_literal: true

class Folio::Console::Boutique::SubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Subscription"

  # def create
  #   @subscription.creating_in_console = true
  #   @subscription.recurrent = false
  #   @subscription.save
  #
  #   respond_with @subscription, location: respond_with_location
  # end

  def cancel
    @subscription.cancel!

    respond_with @subscription, location: url_for([:console, @subscription])
  end

  private
    def subscription_params
      params.require(:subscription)
            .permit(*(@klass.column_names - ["id"]),
                    *addresses_strong_params)
    end

    def index_filters
      {
        by_active: [true, false],
      }
    end
end
