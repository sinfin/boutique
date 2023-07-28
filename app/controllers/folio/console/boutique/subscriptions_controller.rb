# frozen_string_literal: true

class Folio::Console::Boutique::SubscriptionsController < Folio::Console::BaseController
  folio_console_controller_for "Boutique::Subscription", csv: true

  def active
    @subscriptions = @subscriptions.active
    index
  end

  def inactive
    @subscriptions = @subscriptions.inactive
    index
  end

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
        by_recurrent: [true, false],
        by_product_variant_id: {
          klass: "Boutique::ProductVariant",
        },
        by_gift: [true, false],
        by_ordered_at_range: { as: :date_range },
      }
    end

    def folio_console_collection_includes
      [:product_variant, :user]
    end

    def index_tabs
      [
        {
          label: t("folio.console.boutique.subscriptions.index.tabs.all"),
          href: url_for([:console, @klass]),
          force_active: action_name == "index",
        },
        {
          label: t("folio.console.boutique.subscriptions.index.tabs.active"),
          href: url_for([:active, :console, @klass]),
          force_active: action_name == "active",
        },
        {
          label: t("folio.console.boutique.subscriptions.index.tabs.inactive"),
          href: url_for([:inactive, :console, @klass]),
          force_active: action_name == "inactive",
        },
      ]
    end
end
