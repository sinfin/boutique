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

  has_many :active_subscriptions, -> { active },
                                  class_name: "Boutique::Subscription",
                                  foreign_key: :folio_user_id

  def acquire_orphan_records!(old_session_id:)
    Boutique::Order.where(web_session_id: old_session_id,
                          folio_user_id: nil)
                   .update_all(folio_user_id: id,
                               updated_at: Time.current)
  end
end
