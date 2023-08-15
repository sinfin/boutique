# frozen_string_literal: true

require_relative Folio::Engine.root.join("test/factories")

FactoryBot.define do
  factory :boutique_product, class: "Boutique::Product::Basic" do
    title { "Product title" }
    published { true }

    transient do
      code { nil }
      price { nil }
    end

    before(:create) do |product, evaluator|
      if product.vat_rate.nil?
        product.vat_rate = Boutique::VatRate.default || create(:boutique_vat_rate)
      end

      if product.variants.blank?
        product.variants << build(:boutique_product_variant, { product:,
                                                               regular_price: evaluator.price,
                                                               code: evaluator.code,
                                                               title: "#{evaluator.title} - variant A",
                                                               master: true }.compact)
      end
    end
  end

  factory :boutique_product_subscription, class: "Boutique::Product::Subscription", parent: :boutique_product do
    title { "Product Subscription title" }
    subscription_frequency { Boutique::Product::Subscription::SUBSCRIPTION_FREQUENCIES.keys.first }
  end

  factory :boutique_product_variant, class: "Boutique::ProductVariant" do
    association :product, factory: :boutique_product

    sequence(:code) { |i| "CODE#{i}" }
    title { "ProductVariant title" }
    regular_price { 99 }
    subscription_period { product.subscription? ? 12 : 0 }
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

      line_items_count { 1 }

      after(:build) do |order, evaluator|
        unless evaluator.digital_only
          order.first_name ||= "John"
          order.last_name ||= "Doe"
          order.primary_address ||= build(:boutique_folio_primary_address, :with_phone)
          order.shipping_method ||= Boutique::ShippingMethod.published.first || create(:boutique_shipping_method)
        end
      end
    end

    trait :confirmed do
      ready_to_be_confirmed

      aasm_state { "confirmed" }
      confirmed_at { 1.minute.ago }

      after(:build) do |order|
        order.send(:set_numbers)
        order.send(:before_confirm)
        order.send(:imprint)
      end
    end

    trait :waiting_for_offline_payment do
      confirmed
      aasm_state { "waiting_for_offline_payment" }
    end

    trait :paid do
      confirmed
      with_user

      aasm_state { "paid" }
      paid_at { Time.current - 1.minute }

      after(:build) do |order|
        order.confirmed_at = [order.paid_at, order.confirmed_at].min
        order.send(:set_invoice_number)
        order.send(:imprint)
      end

      after(:create) do |order|
        create(:boutique_payment, order:, created_at: order.paid_at)
      end
    end

    trait :gift do
      gift { true }
      sequence(:gift_recipient_email) { |i| "gift-#{i}@email.email" }
    end

    after(:build) do |order, evaluator|
      if order.line_items.empty?
        evaluator.line_items_count.times do
          product_factory = evaluator.subscription_product ? :boutique_product_subscription : :boutique_product
          product_price = (order.read_attribute(:line_items_price) || order.read_attribute(:total_price) || 100) / evaluator.line_items_count
          product_price = product_price / 12.0 if product_factory == :boutique_product_subscription
          product = create(product_factory, price: product_price)

          li = build(:boutique_line_item, product:)
          li.product.update_column(:digital_only, true) if evaluator.digital_only

          order.line_items << li
        end
      end
    end
  end

  factory :boutique_line_item, class: "Boutique::LineItem" do
    association :order, factory: :boutique_order

    subscription_recurring { true }

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
    payment_gateway_provider { Boutique.config.payment_gateways[:default].to_sym }
  end

  factory :boutique_shipping_method, class: "Boutique::ShippingMethod" do
    title { "ShippingMethod title" }
    price { 99 }
    published { true }
  end

  factory :boutique_subscription, class: "Boutique::Subscription" do
    active_from { 1.minute.ago }
    period { 12 }
    active_until { 1.minute.ago + period.months }
    recurrent { true }

    transient do
      digital_only { true }
    end

    after(:build) do |subscription, evaluator|
      unless subscription.product_variant.present?
        order_attrs = {
          digital_only: evaluator.digital_only,
          subscription:,
          subscription_product: true,
          user: subscription.user,
          total_price: 60
        }.compact

        order = create(:boutique_order, :paid, order_attrs)
        subscription.payment = order.payments.paid.first
        subscription.product_variant = order.line_items.first.product_variant
        subscription.user = order.user
        subscription.payer = order.user
      else
        subscription.user ||= create(:folio_user)
      end

      unless evaluator.digital_only
        subscription.primary_address = build(:folio_address_primary)
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

    trait :with_phone do
      phone { "+420604123456" }
    end
  end

  factory :boutique_order_refund, class: "Boutique::OrderRefund" do
    order { create(:boutique_order, :paid, total_price: 123) }

    issue_date { Date.yesterday }
    due_date { issue_date + 14.days }
    date_of_taxable_supply { issue_date }
    reason { "Something was wrong" }
    total_price_in_cents { order.total_price_in_cents }
    payment_method { "VOUCHER" }

    trait :created do
      aasm_state { "created" }
    end

    trait :approved_to_pay do
      created
      aasm_state { "approved_to_pay" }
      approved_at { 1.minute.ago }
      sequence(:document_number) { |i| "23" + i.to_s.rjust(4, "0") }
    end

    trait :paid do
      approved_to_pay
      aasm_state { "paid" }
      paid_at { 1.minute.ago }
    end

    trait :cancelled do
      aasm_state { "cancelled" }
      cancelled_at { 1.minute.ago }
    end
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
