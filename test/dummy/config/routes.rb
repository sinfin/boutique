# frozen_string_literal: true

Rails.application.routes.draw do
  if Rails.application.config.folio_users
    devise_for :accounts, class_name: "Folio::Account",
                          module: "folio/accounts"

    devise_for :users, class_name: "Folio::User",
                       module: "dummy/folio/users",
                       omniauth_providers: Rails.application.config.folio_users_omniauth_providers

    devise_scope :user do
      get "/users/invitation", to: "dummy/folio/users/invitations#show", as: nil
      get "/users/auth/conflict", to: "dummy/folio/users/omniauth_callbacks#conflict"
      get "/users/auth/resolve_conflict", to: "dummy/folio/users/omniauth_callbacks#resolve_conflict"
      get "/users/auth/new_user", to: "dummy/folio/users/omniauth_callbacks#new_user"
      post "/users/auth/create_user", to: "dummy/folio/users/omniauth_callbacks#create_user"
    end
  end

  root to: "home#index"

  mount Folio::Engine => "/"
  mount Boutique::Engine => "/"

  get "/400", to: "errors#page400", via: :all
  get "/404", to: "errors#page404", via: :all
  get "/422", to: "errors#page422", via: :all
  get "/500", to: "errors#page500", via: :all

  resources :pages, only: [:show], path: ""
end
