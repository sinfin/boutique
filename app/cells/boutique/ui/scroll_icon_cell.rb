# frozen_string_literal: true

class Boutique::Ui::ScrollIconCell < ApplicationCell
  def size
    @size ||= (model && model[:size]) || 24
  end
end
