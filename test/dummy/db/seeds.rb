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

def force_destroy(klass)
  puts "Destroying #{klass}"
  klass.find_each { |o| o.try(:force_destroy=, true); o.destroy! }
  puts "Destroyed #{klass}"
end

destroy_all Boutique::Order
destroy_all Boutique::Product
destroy_all Folio::User
force_destroy Folio::Site

puts "Creating Folio::Site"
Folio::Site.create!(title: "Boutique Shop",
                    domain: "boutique.shop",
                    locale: "en",
                    locales: ["en"],
                    email: "info@todo.shop",
                    phone: "+420 123 456 789")
puts "Created Folio::Site"

puts "Creating products & variants"
4.times do
  product = Boutique::Product.new(title: Faker::Commerce.product_name,
                                  published: true,
                                  published_at: 1.minute.ago)
  price = (rand * 10).round * 100 - 1
  product.build_master_variant(title: "#{product.title} – Print + Digital",
                               price: price + 300,
                               digital_only: false)
  product.variants.build(title: "#{product.title} – Print",
                         price: price + 200,
                         digital_only: false)
  product.variants.build(title: "#{product.title} – Digital",
                         price:,
                         digital_only: true)
  product.save!

  print "."
end
puts "\nCreated products & variants"
