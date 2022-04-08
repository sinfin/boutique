# frozen_string_literal: true

FactoryBot.define do
  factory :wipify_order, class: "Wipify::Order" do
    email { "order@email.email" }
  end
end
