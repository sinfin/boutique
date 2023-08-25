# frozen_string_literal: true

class Boutique::Ui::VectorIconCell < ApplicationCell
  def show
    render if model.present? && icon_name.present?
  end

  def icon_name
    model[:icon_name]
  end

  def size
    @size ||= model[:size] || 24
  end

  def style
    unless model[:color].nil?
      "color: #{model[:color] == false ? 'inherit' : model[:color]}"
    end
  end

  def css_class_name
    "b-ui-vector-icon--#{icon_name} #{model[:class]}"
  end

  def icon_path
    case icon_name
    when :gift
      render(:_gift_path)
    when :person
      render(:_person_path)
    when :refresh
      render(:_refresh_path)
    end
  end
end
