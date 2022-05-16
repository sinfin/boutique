# frozen_string_literal: true

module Boutique::ConfigHelper
  ADAPTIVE_CSS_DEFAULTS = {
    background_color: "#EBF0FF",
    main_color: "#0049FB",
  }

  def boutique_adaptive_css_for_head(model, force: false)
    return unless @use_boutique_adaptive_css_for_head || force

    if model && model.respond_to?(:boutique_adaptive_css_for_head)
      override = model.boutique_adaptive_css_for_head
    else
      override = {}
    end

    h = ADAPTIVE_CSS_DEFAULTS.merge(override)

    %{
      <style type="text/css">
        #{@use_boutique_adaptive_css_for_head == :no_background ? "" : "body { background: #{h[:background_color]}; }" }
        .b-adaptive-css-background-primary { background: #{h[:main_color]}; }
        .b-adaptive-css-border-color-primary { border-color: #{h[:main_color]}; }
      </style>
    }.html_safe
  end
end
