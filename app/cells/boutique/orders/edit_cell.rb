# frozen_string_literal: true

class Boutique::Orders::EditCell < Boutique::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def form(&block)
    opts = {
      url: controller.boutique.confirm_order_path,
      method: :post,
      html: { class: "b-orders-edit__form" },
    }

    simple_form_for(current_order, opts, &block)
  end
end
