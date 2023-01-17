# frozen_string_literal: true

class Boutique::Ui::GiftIconCell < ApplicationCell
  def size
    @size ||= (model && model[:size]) || 24
  end
end
