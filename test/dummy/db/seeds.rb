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

destroy_all Folio::File
destroy_all Folio::User
destroy_all Folio::Account
force_destroy Folio::Site
force_destroy Folio::Page

def unsplash_pic(square = false)
  image = Folio::Image.new
  scale = 0.5 + rand / 2
  w = (scale * 2560).to_i
  h = (square ? scale * 2560 : scale * 1440).to_i
  image.file_url = "https://picsum.photos/#{w}/#{h}/?random"
  image.tag_list = "unsplash, seed"
  image.file_name = "unsplash.jpg"
  image.file_width = w
  image.file_height = h
  image.save!

  image
end

puts "Creating Folio::Site"
Folio::Site.create!(title: "Boutique Shop",
                    domain: "boutique.shop",
                    locale: "cs",
                    locales: ["cs", "en"],
                    email: "info@todo.shop",
                    phone: "+420 123 456 789")
puts "Created Folio::Site"

puts "Creating unsplash pics"
images = 4.times.map { unsplash_pic }
puts "Created unsplash pics"

puts "Creating products & variants"
4.times do |i|
  product = Boutique::Product.new(title: Faker::Commerce.product_name,
                                  published: true,
                                  published_at: 1.minute.ago,
                                  cover: images[i])
  price = (3 + rand * 7).round * 100 - 1
  contents = 5.times.map { "<li>#{Faker::Lorem.sentence(word_count: 3, random_words_to_add: 3)}</li>" }
  product.build_master_variant(title: "#{product.title} – Print + Digital",
                               regular_price: price + 300,
                               contents: "<ul>#{contents.join}</ul>",
                               digital_only: false)
  product.variants.build(title: "#{product.title} – Print",
                         regular_price: price + 200,
                         contents: "<ul>#{contents.first(3).join}</ul>",
                         digital_only: false)
  product.variants.build(title: "#{product.title} – Digital",
                         regular_price: price,
                         discounted_price: price - 100,
                         contents: "<ul>#{contents.values_at(0, 1, -1).join}</ul>",
                         digital_only: true)
  product.save!

  print "."
end
puts "\nCreated products & variants"

puts "Creating vouchers"
4.times do |i|
  Boutique::Voucher.create!(title: "50% Discount Voucher",
                            discount: 50,
                            discount_in_percentages: true,
                            published: true,
                            published_from: 1.minute.ago)
  print "."
end
puts "\nCreated vouchers"

[
  [Dummy::Page::DataProtection, "Ochrana osobních údajů"],
  [Dummy::Page::Terms, "Obchodní podmínky"],
].each do |klass, title|
  puts "Creating #{klass}"

  klass.create!(title:,
                published: true,
                published_at: 1.minute.ago)

  puts "Created #{klass}"
end

if Rails.env.development?
  puts "Creating test@test.test account"

  Folio::Account.create!(email: "test@test.test",
                         password: "test@test.test",
                         role: :superuser,
                         first_name: "Test",
                         last_name: "Dummy")

  puts "Created test@test.test account"
end
