# frozen_string_literal: true

Wipify::Engine.routes.draw do
  resource :order, only: [] do
    post :add
  end
end
