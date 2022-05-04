# frozen_string_literal: true

class Boutique::Orders::Edit::TermsCell < Boutique::ApplicationCell
  def privacy_policy_page
    Boutique::Page::PrivacyPolicy.instance
  end

  def terms_page
    Boutique::Page::Terms.instance
  end
end
