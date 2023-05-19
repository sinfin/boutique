# frozen_string_literal: true

class Boutique::ApplicationCell < Folio::ApplicationCell
  include Boutique::PriceHelper

  def current_order
    get_from_options_or_controller(:current_order)
  end

  def application_namespace
    @application_namespace ||= ::Rails.application.class.name.deconstantize
  end

  def application_namespace_path
    @application_namespace_path ||= application_namespace.underscore
  end

  def application_css_class(str)
    @application_namespace_css_class_prefix ||= application_namespace_path[0]
    "#{@application_namespace_css_class_prefix}-#{str}"
  end
end
