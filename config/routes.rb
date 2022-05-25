# frozen_string_literal: true

Boutique::Engine.routes.draw do
  resource :order, only: %i[edit] do
    post :add
    post :confirm
    post :apply_voucher
    post :payment, path: "/:id/payment"
  end

  get "order/:id", to: "orders#show", as: :order

  resource :go_pay, only: [], controller: :go_pay do
    get :comeback
    get :notify
  end
end

Folio::Engine.routes.draw do
  namespace :console do
    scope module: :boutique do
      resources :orders, only: %i[index show edit update]
      resources :products
    end
  end
end
