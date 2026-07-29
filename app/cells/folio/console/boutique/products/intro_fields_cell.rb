# frozen_string_literal: true

# The introductory price belongs next to the regular one in the product form,
# even though only a subscription can have it.
class Folio::Console::Boutique::Products::IntroFieldsCell < Folio::ConsoleCell
  include Folio::Console::Boutique::ProductTypeHelper

  PRODUCT_TYPE = "Boutique::Product::Subscription"

  def f
    model
  end

  def enabled_class
    "f-c-b-products-intro-fields--active" if f.object.intro_enabled?
  end
end
