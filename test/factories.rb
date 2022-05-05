# frozen_string_literal: true

require_relative Folio::Engine.root.join("test/factories")

FactoryBot.define do
  factory :boutique_product, class: "Boutique::Product" do
    title { "Product title" }

    transient do
      price { 99 }
    end

    before(:create) do |product, evaluator|
      product.master_variant = build(:boutique_product_variant, regular_price: evaluator.price,
                                                                master: true)
    end
  end

  factory :boutique_product_variant, class: "Boutique::ProductVariant" do
    association :product, factory: :boutique_product

    title { "ProductVariant title" }
    regular_price { 99 }
  end

  factory :boutique_order, class: "Boutique::Order" do
    transient do
      digital_only { false }
      line_items_count { 0 }
    end

    trait :ready_to_be_confirmed do
      email { "order@email.email" }
      first_name { "John" }
      last_name { "Doe" }

      line_items_count { 1 }

      before(:create) do |order, evaluator|
        if order.primary_address.nil? && !evaluator.digital_only
          order.primary_address = build(:boutique_folio_primary_address)
        end
      end
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
          li = build(:boutique_line_item)
          li.product_variant.update_column(:digital_only, true) if evaluator.digital_only
          order.line_items << li
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

  factory :boutique_folio_primary_address, class: "Folio::Address::Primary" do
    name { "name" }
    address_line_1 { "address_line_1" }
    city { "city" }
    zip { "12345" }
    country_code { "US" }
  end
end
