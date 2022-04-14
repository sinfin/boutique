# frozen_string_literal: true

module Wipify::ApplicationControllerBase
  extend ActiveSupport::Concern

  include Wipify::CurrentOrder
end
