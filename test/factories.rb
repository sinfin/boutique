# frozen_string_literal: true

require_relative Folio::Engine.root.join("test/factories")

FactoryBot.define do
  factory :boutique_product, class: "Boutique::Product" do
    title { "Product title" }

    transient do
      price { 99 }
    end

    before(:create) do |product, evaluator|
      product.master_variant = build(:boutique_product_variant, price: evaluator.price,
                                                              master: true)
    end
  end

  factory :boutique_product_variant, class: "Boutique::ProductVariant" do
    # association :product, factory: :boutique_product

    title { "ProductVariant title" }
    price { 99 }
  end

  factory :boutique_order, class: "Boutique::Order" do
    transient do
      line_items_count { 0 }
    end

    trait :ready_to_be_confirmed do
      email { "order@email.email" }
      line_items_count { 1 }

      association :primary_address, factory: :boutique_folio_primary_address
      association :payment_method, factory: :boutique_payment_method
      association :shipping_method, factory: :boutique_shipping_method
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
          order.line_items << build(:boutique_line_item)
        end
      end
    end
  end

  factory :boutique_line_item, class: "Boutique::LineItem" do
    association :order, factory: :boutique_order

    transient do
      product { create(:boutique_product) }
    end

    after(:build) do |line_item, evaluator|
      line_item.product_variant ||= evaluator.product.master_variant
    end
  end


  factory :boutique_payment_method, class: "Boutique::PaymentMethod" do
    title { "PaymentMethod title" }
    price { 0 }
    published { true }
  end

  factory :boutique_shipping_method, class: "Boutique::ShippingMethod" do
    title { "ShippingMethod title" }
    price { 0 }
    published { true }
  end

  factory :boutique_folio_primary_address, class: "Folio::Address::Primary" do
    name { "name" }
    address_line_1 { "address_line_1" }
    city { "city" }
    zip { "12345" }
    country_code { "US" }
  end
end
