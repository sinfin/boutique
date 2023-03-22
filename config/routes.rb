# frozen_string_literal: true

Boutique::Engine.routes.draw do
  resource :order, only: %i[edit] do
    get :refreshed_edit
    get :crossdomain_add, path: "crossdomain_add/:product_variant_slug"
    post :add
    post :confirm
    post :apply_voucher
    post :payment, path: "/:id/payment"
  end

  localized do
    resources :products, only: %i[show]
  end

  get "order/:id", to: "orders#show", as: :order
  get "invoice/:secret_hash", to: "invoices#show", as: :invoice

  resource :go_pay, only: [], controller: :go_pay do
    get :comeback
    get :notify
  end
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
