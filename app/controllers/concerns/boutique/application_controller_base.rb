# frozen_string_literal: true

module Boutique::ApplicationControllerBase
  extend ActiveSupport::Concern

  include Boutique::CurrentOrder
end
