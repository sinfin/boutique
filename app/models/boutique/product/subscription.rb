# frozen_string_literal: true

class Boutique::Product::Subscription < Boutique::Product
end

# == Schema Information
#
# Table name: boutique_products
#
#  id             :bigint(8)        not null, primary key
#  title          :string           not null
#  slug           :string           not null
#  published      :boolean          default(FALSE)
#  published_at   :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  type           :string
#  variants_count :integer          default(0)
#
# Indexes
#
#  index_boutique_products_on_published     (published)
#  index_boutique_products_on_published_at  (published_at)
#  index_boutique_products_on_slug          (slug)
#  index_boutique_products_on_type          (type)
#
