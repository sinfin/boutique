# frozen_string_literal: true

already_loaded = Folio::User.method_defined?(:orders)
return if already_loaded

Folio::User.class_eval do
  has_many :orders, class_name: "Boutique::Order",
                    inverse_of: :user,
                    foreign_key: :folio_user_id,
                    dependent: :nullify
  has_many :subscriptions, class_name: "Boutique::Subscription",
                    inverse_of: :user,
                    foreign_key: :folio_user_id,
                    dependent: :nullify
end
