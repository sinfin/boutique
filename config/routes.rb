# frozen_string_literal: true

Boutique::Engine.routes.draw do
  order_actions = %i[edit update]
  order_actions += %i[show] if Boutique.using_cart

  resource :order, only: order_actions do
    post :add
    post :confirm
    get :thank_you, path: "/thank_you/:id"
    get :failure, path: "/failure/:id"
  end

  resource :go_pay, only: [], controller: :go_pay do
    get :comeback
    get :notify
  end
end

Folio::Engine.routes.draw do
  namespace :console do
    scope module: :boutique do
      resources :orders, only: %i[index show edit update]
    end
  end
end
