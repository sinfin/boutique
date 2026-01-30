# frozen_string_literal: true

class Boutique::Orders::SummaryCell < Boutique::ApplicationCell
  include SimpleForm::ActionViewExtensions::FormHelper
  include Boutique::SubscriptionHelper

  THUMB_SIZE = "50x50#"

  def form(&block)
    if model.pending?
      opts = {
        # url: controller.boutique.checkout_path,
        url: "/TODO",
        method: :post,
        html: { class: "b-orders-summary__form" },
      }

      simple_form_for(model, opts, &block)
    else
      block.call(nil)
    end
  end

  def fields_for_line_item(f, line_item, &block)
    f.simple_fields_for :line_items, line_item do |subfields|
      (yield subfields).html_safe
    end
  end

  def line_item_tag_additional_class(line_item)
    if line_item.subscription_recurring? || line_item.subscription_period.nil?
      "b-orders-summary__tag--recurring"
    end
  end

  def line_item_tag_label(line_item)
    if line_item.subscription_recurring? || line_item.subscription_period.nil?
      [
        image_tag("boutique/refresh.svg", class: "b-orders-summary__tag-img"),
        t(".recurring_payment")
      ].join
    else
      t(".single_payment", months: duration_to_human(line_item.subscription_period))
    end
  end

  def product_variant_input(f)
    f.association(:product_variant,
                  collection: f.object.product.variants,
                  include_blank: false,
                  label: false,
                  wrapper_html: { class: "b-orders-cart-summary__product-variants-wrap" },
                  input_html: { class: "b-orders-cart-summary__product-variants-select" })
  end

  def subscription_period(line_item)
    label = t(".subscription_period.months", count: line_item.subscription_period)

    if model.renewed_subscription.present?
      date = l(model.renewed_subscription.active_until + 1.day, format: :as_date)
      label += ", #{t(".subscription_period.from", date:)}"
    end

    label
  end
end
