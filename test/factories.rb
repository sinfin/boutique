# frozen_string_literal: true

FactoryBot.define do
  factory :wipify_product, class: "Wipify::Product" do
    title { "Product title" }

    transient do
      price { 99 }
    end

    before(:create) do |product, evaluator|
      product.master_variant = build(:wipify_product_variant, price: evaluator.price,
                                                              master: true)
    end
  end

  factory :wipify_product_variant, class: "Wipify::ProductVariant" do
    # association :product, factory: :wipify_product

    title { "ProductVariant title" }
    price { 99 }
  end

  factory :wipify_order, class: "Wipify::Order" do
    transient do
      line_items_count { 0 }
    end

    trait :ready_to_be_confirmed do
      email { "order@email.email" }
      line_items_count { 1 }

      association :payment_method, factory: :wipify_payment_method
      association :shipping_method, factory: :wipify_shipping_method
    end

    trait :confirmed do
      ready_to_be_confirmed

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

    before(:create) do |order, evaluator|
      if order.line_items.empty?
        evaluator.line_items_count.times do
          order.line_items << build(:wipify_line_item)
        end
      end
    end
  end

  factory :wipify_line_item, class: "Wipify::LineItem" do
    association :order, factory: :wipify_order

    transient do
      product { create(:wipify_product) }
    end

    after(:build) do |line_item, evaluator|
      line_item.product_variant ||= evaluator.product.master_variant
    end
  end


  factory :wipify_payment_method, class: "Wipify::PaymentMethod" do
    title { "PaymentMethod title" }
    price { 0 }
    published { true }
  end

  factory :wipify_shipping_method, class: "Wipify::ShippingMethod" do
    title { "ShippingMethod title" }
    price { 0 }
    published { true }
  end
end
