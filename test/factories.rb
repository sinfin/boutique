# frozen_string_literal: true

require_relative Folio::Engine.root.join("test/factories")

FactoryBot.define do
  factory :boutique_product, class: "Boutique::Product::Basic" do
    title { "Product title" }
    published { true }
    sequence(:code) { |i| "CODE#{i}" }
    regular_price { 99 }

    vat_rate { Boutique::VatRate.default || create(:boutique_vat_rate) }

    before(:create) do |product|
      if product.variants.blank?
        product.variants << build(:boutique_product_variant, master: true)
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
  end

  factory :boutique_order, class: "Boutique::Order" do
    transient do
      subscription_product { false }
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

        order.line_items.each { |li| li.product_variant ||= li.product.master_variant }
      end
    end

    trait :confirmed do
      ready_to_be_confirmed

      aasm_state { "confirmed" }
      confirmed_at { 1.minute.ago }

      before(:create) do |order|
        order.send(:set_numbers)
        order.send(:imprint)
      end
    end

    trait :paid do
      confirmed
      with_user

      aasm_state { "paid" }
      paid_at { 1.minute.ago }

      before(:create) do |order|
        order.paid_at = Time.current
        order.send(:set_invoice_number)
        order.send(:imprint)
      end

      after(:create) do |order|
        create(:boutique_payment, order:)
      end
    end

    trait :gift do
      gift { true }
      sequence(:gift_recipient_email) { |i| "gift-#{i}@email.email" }
      gift_recipient_first_name { "John" }
      gift_recipient_last_name { "Doe" }
      gift_recipient_notification_scheduled_for { 1.hour.from_now }
    end

    before(:create) do |order, evaluator|
      if order.line_items.empty?
        evaluator.line_items_count.times do
          product = evaluator.subscription_product ? create(:boutique_product_subscription) : create(:boutique_product)
          li = build(:boutique_line_item, product:)
          li.product.update_column(:digital_only, true) if evaluator.digital_only
          order.line_items << li
        end
      end
    end
  end

  factory :boutique_line_item, class: "Boutique::LineItem" do
    association :order, factory: :boutique_order
    association :product, factory: :boutique_product

    subscription_recurring { true }
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

    association :primary_address, factory: :folio_address_primary, name: "name"

    after(:build) do |subscription|
      unless subscription.product_variant.present?
        order_attrs = { subscription:, subscription_product: true, user: subscription.user }.compact
        order = create(:boutique_order, :paid, order_attrs)
        subscription.payment = order.payments.paid.first
        subscription.product_variant = order.line_items.first.product_variant
        subscription.user = order.user
        subscription.payer = order.user
      else
        subscription.user = create(:folio_user)
      end
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
