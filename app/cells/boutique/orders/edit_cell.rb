# frozen_string_literal: true

class Boutique::Orders::EditCell < Boutique::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def show
    if current_user.present?
      if current_order.primary_address.nil?
        current_order.primary_address = current_user.primary_address.dup
      end

      if current_order.secondary_address.nil?
        current_order.use_secondary_address = current_user.secondary_address.present?
        current_order.secondary_address = current_user.secondary_address.dup
      end
    end

    render
  end

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
