# frozen_string_literal: true

class Boutique::Orders::ShowCell < Boutique::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper

  def payment_methods_form(&block)
    opts = {
      url: controller.boutique.payment_order_path(model.secret_hash),
      html: { class: "b-orders-show__payment-methods-form" },
      method: :post,
    }

    simple_form_for(model, opts, &block)
  end
end
