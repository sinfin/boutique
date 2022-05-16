# frozen_string_literal: true

class Boutique::ApplicationController < Boutique.config.parent_controller.constantize
  include Boutique::ApplicationControllerBase
end
