# frozen_string_literal: true

require_relative Folio::Engine.root.join("test/factories")

FactoryBot.define do
  factory :boutique_product, class: "Boutique::Product::Basic" do
    title { "Product title" }

    transient do
      price { 99 }
    end

    before(:create) do |product, evaluator|
      if product.vat_rate.nil?
        product.vat_rate = Boutique::VatRate.default || create(:boutique_vat_rate)
      end

      if product.variants.blank?
        product.variants << build(:boutique_product_variant,
                                  regular_price: evaluator.price,
                                  master: true)
      end
    end
  end

  factory :boutique_product_subscription, class: "Boutique::Product::Subscription", parent: :boutique_product do
    title { "Product Subscription title" }
    subscription_frequency { Boutique::Product::Subscription::SUBSCRIPTION_FREQUENCIES.keys.first }
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

    trait :with_user do
      association :user, factory: :folio_user
    end

    trait :ready_to_be_confirmed do
      sequence(:email) { |i| "order-#{i}@email.email" }
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

      aasm_state { "confirmed" }
      confirmed_at { 1.minute.ago }

      before(:create) do |order|
        order.send(:set_numbers)
        order.send(:imprint_prices)
      end
    end

    trait :paid do
      confirmed
      with_user

      aasm_state { "paid" }
      paid_at { 1.minute.ago }

      before(:create) do |order|
        order.send(:set_invoice_number)
        order.send(:imprint_prices)
      end

      after(:create) do |order|
        create(:boutique_payment, order:)
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

  factory :boutique_payment, class: "Boutique::Payment" do
    association :order, factory: :boutique_order

    remote_id { 12345678 }
    aasm_state { "paid" }
    paid_at { 1.minute.ago }
  end

  factory :boutique_subscription, class: "Boutique::Subscription" do
    active_from { 1.minute.ago }
    active_until { 1.minute.ago + 12.months }

    after(:build) do |subscription|
      order_attrs = { subscription:, user: subscription.user }.compact
      order = create(:boutique_order, :paid, order_attrs)
      subscription.payment = order.payments.paid.first
      subscription.product_variant = order.line_items.first.product_variant
      subscription.user = order.user
    end
  end

  factory :boutique_vat_rate, class: "Boutique::VatRate" do
    title { "VatRate title" }
    sequence(:value) { |i| 10 + i }

    before(:create) do |vat_rate|
      vat_rate.default = true unless Boutique::VatRate.exists?
    end
  end

  factory :boutique_voucher, class: "Boutique::Voucher" do
    published { true }
    published_from { 1.minute.ago }
    title { "Voucher title" }
    discount { 50 }
  end

  factory :boutique_folio_primary_address, class: "Folio::Address::Primary" do
    address_line_1 { "address_line_1" }
    city { "city" }
    zip { "12345" }
    country_code { "US" }
  end
end

FactoryBot.modify do
  factory :folio_site do
    billing_name { "Site billing_name" }
    billing_address_line_1 { "Site billing_address_line_1" }
    billing_address_line_2 { "Site billing_address_line_2" }
    billing_identification_number { "12345678" }
    billing_vat_identification_number { "CZ12345678" }
    billing_note { "Site billing_note" }
  end
end
