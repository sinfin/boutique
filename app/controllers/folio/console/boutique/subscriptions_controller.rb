# frozen_string_literal: true

class Folio::Console::Boutique::SubscriptionsController < Folio::Console::BaseController
  before_action :find_user
  before_action :find_subscription, except: %i[new create]

  folio_console_controller_for "Boutique::Subscription", through: "Folio::User"

  def new
    if @user.primary_address.present?
      @subscription.primary_address = @user.primary_address.dup
      @subscription.primary_address.name = @user.full_name
    end
  end

  def create
    @subscription.creating_in_console = true
    @subscription.cancelled_at = @subscription.active_from
    @subscription.save

    respond_with @subscription, location: respond_with_location
  end

  def cancel
    @subscription.cancel!

    respond_with @subscription, location: respond_with_location
  end

  private
    def subscription_params
      params.require(:subscription)
            .permit(*(@klass.column_names - ["id"]),
                    *addresses_strong_params)
    end

    def respond_with_location
      url_for([:console, @user])
    end

    def find_user
      @user = Folio::User.find(params[:user_id])
    end

    def find_subscription
      @subscription = @user.subscriptions.find(params[:id])
    end
end
