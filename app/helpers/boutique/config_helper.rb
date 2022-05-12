# frozen_string_literal: true

module Boutique::ConfigHelper
  ADAPTIVE_CSS_DEFAULTS = {
    background: "#EBF0FF",
    border_color: "#0049FB",
  }

  def boutique_adaptive_css_for_head(model)
    if model && model.respond_to?(:boutique_adaptive_css_for_head)
      override = model.boutique_adaptive_css_for_head
    else
      override = {}
    end

    h = ADAPTIVE_CSS_DEFAULTS.merge(override)

    %{
      <style type="text/css">
        .b-adaptive-css-main-background { background: #{h[:background]}; }
        .b-adaptive-css-background-primary { background: #{h[:border_color]}; }
        .b-adaptive-css-border-color-primary { border-color: #{h[:border_color]}; }
      </style>
    }.html_safe
  end
end
