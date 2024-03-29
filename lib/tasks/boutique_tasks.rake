# frozen_string_literal: true

namespace :boutique do
  desc "Seeds Boutique::VatRate records"
  task idp_seed_vat_rates: :environment do
    Rails.logger.silence do
      if ENV["FORCE"]
        Boutique::VatRate.delete_all
      end

      if Boutique::VatRate.exists?
        puts "Boutique::VatRate records already present!"
      else
        puts "Seeding vat rates"

        [
          ["Default rate", 21, true],
          ["Reduced rate 15%", 15, false],
          ["Reduced rate 10%", 10, false],
        ].each do |title, value, default|
          Boutique::VatRate.create!(title:,
                                    value:,
                                    default:)
          print "."
        end

        puts "\nSeeded vat rates"
      end
    end
  end

  desc "Seeds dummy Boutique::Product records"
  task idp_seed_dummy_products: :environment do
    require "faker"

    def create_product(options = {})
      product_class = options.delete(:class) || Boutique::Product::Basic
      contents = 4.times.map { "<li>#{Faker::Lorem.sentence(word_count: 3, random_words_to_add: 3)}</li>" }

      product = product_class.new(options.merge(published: true,
                                                published_at: 1.minute.ago,
                                                code: Faker::Alphanumeric.unique.alpha(number: 5).upcase,
                                                regular_price: (3 + rand * 7).round * 100 - 1,
                                                checkout_sidebar_content: "<ul>#{contents.join}</ul>",
                                                description: "<p>#{Faker::Lorem.sentence(word_count: 3, random_words_to_add: 3)}</p>",
                                                digital_only: false))
      product.variants.build(master: true)
      product.save!
    end

    puts "Seeding 4 dummy products"

    Rails.logger.silence do
      images = Folio::Image.tagged_with("unsplash").limit(4)

      2.times do |i|
        create_product(title: Faker::Commerce.product_name,
                       cover: images[i])
        print "."
      end

      2.times do |i|
        create_product(class: Boutique::Product::Subscription,
                       title: Faker::Commerce.department + " Subscription",
                       cover: images[i + 2],
                       subscription_frequency: Boutique::Product::Subscription::SUBSCRIPTION_FREQUENCIES.keys.first)
        print "."
      end
    end

    puts "\nSeeded 4 dummy products"
  end
end
