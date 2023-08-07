# frozen_string_literal: true

class Folio::Console::Boutique::OrderRefunds::Index::CorrectiveTaxDocumentsButtonCell < Folio::ConsoleCell
  def url
    h = {
      by_query: controller.params[:by_query],
    }

    controller.send(:index_filters).keys.each do |key|
      if controller.params[key].present?
        h[key] = controller.params[key]
      end
    end

    url_for([:corrective_tax_documents, :console, Boutique::OrderRefund, h])
  end
end
