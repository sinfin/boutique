# frozen_string_literal: true

require "faker"

if Rails.env.development?
  ActiveJob::Base.queue_adapter = :inline
end

def destroy_all(klass)
  puts "Destroying #{klass}"
  klass.destroy_all
  puts "Destroyed #{klass}"
end

destroy_all Wipify::Order
destroy_all Wipify::Product

puts "Creating Wipify::Product & variants"

4.times do
  product = Wipify::Product.new(title: Faker::Commerce.product_name)
  product.build_master_variant(price: Faker::Commerce.price(range: 1..100))
  product.save!

  print "."
end

puts "\nCreated Wipify::Product & variants"
