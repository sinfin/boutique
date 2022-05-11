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

  def sign_in_link
    link_to(t(".sign_in"),
            controller.main_app.new_user_session_path,
            data: {
              toggle: "modal",
              target: Folio::Devise::ModalCell::CLASS_NAME,
              action: "sign_in",
            })
  end
end
