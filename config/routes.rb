# frozen_string_literal: true

Boutique::Engine.routes.draw do
  order_actions = %i[edit update]
  order_actions += %i[show] if Rails.application.config.boutique_using_cart

  resource :order, only: order_actions do
    post :add
    post :confirm
    get :thank_you, path: "/thank_you/:id"
  end
end

Folio::Engine.routes.draw do
  namespace :console do
    scope module: :boutique do
      resources :orders, only: %i[index show edit update]
    end
  end
end
