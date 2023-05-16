# frozen_string_literal: true

Boutique::Engine.routes.draw do
  scope constraints: Boutique.config.checkout_routes_constraints do
    resource :order, only: %i[edit] do
      get :refreshed_edit
      get :crossdomain_add, path: "crossdomain_add/:product_slug"
      post :add, path: "add/:product_slug"
      delete :remove_item, path: "remove_item/:line_item_id"
      post :confirm
      post :apply_voucher
      post :payment, path: "/:id/payment"
    end
  end

  localized do
    resources :products, only: %i[show]
  end

  get "order/:id", to: "orders#show", as: :order
  get "invoice/:secret_hash", to: "invoices#show", as: :invoice

  get "after_payment", to: "payment_gateways#after_payment", as: :return_after_pay # URL address for return to e-shop (with protocol)
  get "payment_callback", to: "payment_gateways#payment_callback", as: :payment_callback # URL address for sending asynchronous notification in the case of changes in the payment status (with protocol)
  # legacy redirection
  get "go_pay/comeback", to: "payment_gateways#after_payment"
  get "go_pay/notify", to: "payment_gateways#payment_callback"
end

Folio::Engine.routes.draw do
  namespace :console do
    scope module: :boutique do
      resources :orders, only: %i[index show edit update] do
        collection do
          get :invoices
        end
      end

      resources :products, except: %i[show]
      resources :vat_rates, except: %i[show]
      resources :vouchers, except: %i[show]

      resources :users, only: [] do
        resources :subscriptions, except: %i[show destroy], controller: :subscriptions do
          member do
            delete :cancel
          end
        end
      end
    end
  end
end
