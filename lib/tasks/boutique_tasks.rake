# frozen_string_literal: true

namespace :boutique do
  desc "Seeds dummy Boutique::Product records"
  task idp_seed_dummy_products: :environment do
    require "faker"

    puts "Seeding 4 dummy products"

    Rails.logger.silence do
      images = Folio::Image.tagged_with("unsplash").limit(4)

      4.times do |i|
        product = Boutique::Product.new(title: Faker::Commerce.product_name,
                                        published: true,
                                        published_at: 1.minute.ago,
                                        cover: images[i])

        price = (3 + rand * 7).round * 100 - 1
        contents = 5.times.map { "<li>#{Faker::Lorem.sentence(word_count: 3, random_words_to_add: 3)}</li>" }
        product.variants.build(title: "#{product.title} – Print + Digital",
                               regular_price: price + 300,
                               checkout_sidebar_content: "<ul>#{contents.join}</ul>",
                               description: Faker::Lorem.sentence(word_count: 3, random_words_to_add: 3),
                               digital_only: false,
                               master: true)
        product.variants.build(title: "#{product.title} – Print",
                               regular_price: price + 200,
                               checkout_sidebar_content: "<ul>#{contents.first(3).join}</ul>",
                               description: Faker::Lorem.sentence(word_count: 3, random_words_to_add: 3),
                               digital_only: false)
        product.variants.build(title: "#{product.title} – Digital",
                               regular_price: price,
                               discounted_price: price - 100,
                               checkout_sidebar_content: "<ul>#{contents.values_at(0, 1, -1).join}</ul>",
                               description: Faker::Lorem.sentence(word_count: 3, random_words_to_add: 3),
                               digital_only: true)
        product.save!

        print "."
      end
    end

    puts "\nSeeded 4 dummy products"
  end
end
