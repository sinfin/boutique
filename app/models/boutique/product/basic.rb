# frozen_string_literal: true

class Boutique::Product::Basic < Boutique::Product
end

# == Schema Information
#
# Table name: boutique_products
#
#  id                                      :bigint(8)        not null, primary key
#  title                                   :string           not null
#  slug                                    :string           not null
#  published                               :boolean          default(FALSE)
#  published_at                            :datetime
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  type                                    :string
#  variants_count                          :integer          default(0)
#  subscription_frequency                  :string
#  boutique_vat_rate_id                    :bigint(8)        not null
#  site_id                                 :bigint(8)
#  shipping_info                           :text
#  digital_only                            :boolean          default(FALSE)
#  subscription_recurrent_payment_disabled :boolean          default(FALSE)
#  preview_token                           :string
#  code                                    :string(32)
#  checkout_sidebar_content                :text
#  description                             :text
#  subscription_period                     :integer          default(12)
#  regular_price                           :integer
#  discounted_price                        :integer
#  discounted_from                         :datetime
#  discounted_until                        :datetime
#  best_offer                              :boolean          default(FALSE)
#  variant_type_title                      :string
#
# Indexes
#
#  index_boutique_products_on_boutique_vat_rate_id  (boutique_vat_rate_id)
#  index_boutique_products_on_published             (published)
#  index_boutique_products_on_published_at          (published_at)
#  index_boutique_products_on_site_id               (site_id)
#  index_boutique_products_on_slug                  (slug)
#  index_boutique_products_on_type                  (type)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_vat_rate_id => boutique_vat_rates.id)
#
