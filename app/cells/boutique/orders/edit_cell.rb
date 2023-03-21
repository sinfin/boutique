# frozen_string_literal: true

class Boutique::Orders::EditCell < Boutique::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include ActionView::Helpers::FormOptionsHelper

  def show
    assign_name_and_addresses

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

  def password_reset_link
    link_to(t(".password_reset"), controller.main_app.new_user_password_path)
  end

  def email_input(f)
    if f.object.errors.added?(:email, :already_registered)
      custom_error = t(".email_already_registered",
                       sign_in_link:,
                       password_reset_link:)
    else
      custom_error = false
    end

    f.input :email, required: true, error: custom_error
  end

  def addresses_fields_title
    default_title = if current_order.requires_address?
      t(".addresses_fields_title.default")
    else
      t(".addresses_fields_title.contact")
    end

    [
      content_tag(:span, default_title,
                         class: "b-orders-edit__addresses-fields-title b-orders-edit__addresses-fields-title--default",
                         style: ("display: none;" if current_order.gift?)),
      content_tag(:span, t(".addresses_fields_title.payer_contact"),
                         class: "b-orders-edit__addresses-fields-title b-orders-edit__addresses-fields-title--gift",
                         style: ("display: none;" unless current_order.gift?)),
    ].join
  end

  def subscription?
    @subscription ||= current_order.line_items.any?(&:subscription?)
  end

  def disclaimer
    cell("#{application_namespace_path}/ui/disclaimer",
         nil,
         order: current_order).show
  end

  def product_variant_description
    @product_variant_description ||= current_order&.line_items&.first&.product_variant&.checkout_sidebar_content
  end

  private
    def assign_name_and_addresses
      if current_user.present? && !current_order.changed?

        if current_order.renewed_subscription.try(:primary_address).present?
          names = current_order.renewed_subscription.primary_address.name.split(" ", 2)
        else
          names = [current_user.first_name, current_user.last_name]
        end

        current_order.first_name ||= names.first
        current_order.last_name ||= names.last

        if !current_order.digital_only? && current_order.primary_address.nil?
          if current_order.renewed_subscription.present?
            current_order.primary_address = current_order.renewed_subscription.primary_address.dup
          else
            current_order.primary_address = current_user.primary_address.dup
          end
        end

        if current_order.secondary_address.nil?
          current_order.use_secondary_address = current_user.secondary_address.present?
          current_order.secondary_address = current_user.secondary_address.dup
        end
      end
    end
end
