# frozen_string_literal: true

Rails.application.routes.draw do
  mount Wipify::Engine => "/"

  root to: "home#index"
end
