# frozen_string_literal: true

class Folio::Console::Boutique::Products::StiFieldsCell < Folio::ConsoleCell
  def f
    model
  end

  def render_sti_fields(type)
    style = "display: none" unless f.object.type == type

    content_tag :div, class: "f-c-b-products-sti-fields__inputs",
                      style:,
                      data: { type: } do
      render("_#{type.demodulize.underscore}")
    end
  end

  def type_input
    f.input :type,
            collection: Boutique::Product.recursive_subclasses_for_select(include_self: false),
            include_blank: false,
            required: false,
            input_html: { class: "f-c-b-products-sti-fields__type-input" }
  end

  def subscription_frequency_input
    f.input :subscription_frequency,
            collection: Boutique::Product::Subscription.subscription_frequency_options_for_select,
            include_blank: false
  end
end
