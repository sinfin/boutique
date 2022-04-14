# frozen_string_literal: true

Wipify::Engine.routes.draw do
  resource :order, only: %i[show edit update] do
    post :add
    post :confirm
    get :thank_you, path: "/thank_you/:id"
  end
end
