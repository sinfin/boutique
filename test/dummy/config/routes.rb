# frozen_string_literal: true

Rails.application.routes.draw do
  root to: "home#index"

  mount Folio::Engine => "/"
  mount Boutique::Engine => "/"

  if Rails.application.config.folio_users
    devise_for :accounts, class_name: "Folio::Account", module: "folio/accounts"
    devise_for :users, class_name: "Folio::User",
                       omniauth_providers: Rails.application.config.folio_users_omniauth_providers
  end

  get "/400", to: "errors#page400", via: :allr
  get "/404", to: "errors#page404", via: :all
  get "/422", to: "errors#page422", via: :all
  get "/500", to: "errors#page500", via: :all

  resources :pages, only: [:show], path: "" do
    member { get :preview }
  end
end
