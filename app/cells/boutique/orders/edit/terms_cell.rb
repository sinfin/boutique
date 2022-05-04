# frozen_string_literal: true

class Boutique::Orders::Edit::TermsCell < Boutique::ApplicationCell
  def data_protection_page
    Boutique.data_protection_page_type.constantize.instance
  end

  def terms_page
    Boutique.terms_page_type.constantize.instance
  end
end
