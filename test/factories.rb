# frozen_string_literal: true

FactoryBot.define do
  factory :wipify_order, class: "Wipify::Order" do
    email { "order@email.email" }

    trait :confirmed do
      after(:create) do |order|
        order.confirm!
      end
    end

    trait :paid do
      confirmed

      after(:create) do |order|
        order.pay!
      end
    end
  end
end
