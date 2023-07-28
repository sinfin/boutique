# frozen_string_literal: true

class Folio::Console::Boutique::Orders::Index::InvoicesButtonCell < Folio::ConsoleCell
  def href
    h = {
      by_query: controller.params[:by_query],
    }

    controller.send(:index_filters).keys.each do |key|
      if controller.params[key].present?
        h[key] = controller.params[key]
      end
    end

    url_for([:invoices, :console, Boutique::Order, h])
  end
end
