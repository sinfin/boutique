# frozen_string_literal: true

class Boutique::ApplicationCell < Folio::ApplicationCell
  include Boutique::PriceHelper

  def current_user
    controller.current_user
  end

  def current_order
    controller.current_order
  end

  def application_namespace
    @application_namespace ||= ::Rails.application.class.name.deconstantize
  end

  def application_namespace_path
    @application_namespace_path ||= application_namespace.underscore
  end
end
