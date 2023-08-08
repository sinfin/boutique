# frozen_string_literal: true

class Boutique::OrderRefunds::LineCell < Boutique::ApplicationCell
  def date_range
    return "" unless model.subscription_refund_from.present?

    " (#{l(model.subscription_refund_from)} - #{l(model.subscription_refund_to)})"
  end

  def link_to_document
    return "" if model.document_number.blank?

    link_to(
      t(".download_tax_document"),
      controller.boutique.corrective_tax_document_path(model.secret_hash)
    )
  end
end
