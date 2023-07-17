# frozen_string_literal: true

Boutique::Engine.routes.draw do
  localized do
    scope constraints: Boutique.config.checkout_routes_constraints do
      resource :checkout, only: [], controller: :checkout do
        get :cart
        get :refreshed_cart
        get :crossdomain_add_item, path: "crossdomain_add_item/:product_slug"
        post :add_item, path: "add_item/:product_slug"
        delete :remove_item, path: "remove_item/:line_item_id"
        post :confirm
        post :apply_voucher
      end
    end

    resources :products, only: %i[show]

    resources :orders, only: %i[show], path: "order" do
      member do
        post :payment
      end
    end

    get "invoice/:secret_hash", to: "invoices#show", as: :invoice
  end


  get "after_payment", to: "payment_gateways#after_payment", as: :return_after_pay # URL address for return to e-shop (with protocol)
  match "payment_callback", to: "payment_gateways#payment_callback", via: [:get, :post], as: :payment_callback # URL address for sending asynchronous notification in the case of changes in the payment status (with protocol)

  # legacy redirection
  get "go_pay/comeback", to: "payment_gateways#after_payment"
  get "go_pay/notify", to: "payment_gateways#payment_callback"
end

Folio::Engine.routes.draw do
  scope constraints: Boutique.config.console_routes_constraints do
    namespace :console do
      scope module: :boutique do
        resources :orders, only: %i[index show edit update] do
          collection do
            get :invoices
          end
        end

        resources :subscriptions, except: %i[new create destroy], controller: :subscriptions do
          member do
            delete :cancel
          end
        end

        resources :products, except: %i[show]

        resources :shipping_methods, except: %i[show] do
          post :set_positions, on: :collection
        end

        resources :vat_rates, except: %i[show]
        resources :vouchers, except: %i[show]

        resources :users, only: [] do
        end
      end
    end
  end

  namespace :console do
    scope module: :boutique do
      resources :subscriptions, only: %i[index show], controller: :subscriptions
    end
  end
end
