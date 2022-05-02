# frozen_string_literal: true

class Dummy::Ui::FlashCell < ApplicationCell
  BOOTSTRAP_CLASSES = {
    alert: "alert-danger",
    error: "alert-danger",
    notice: "alert-info",
    success: "alert-success",
    warning: "alert-warning",
  }.freeze

  def bootstrap_class_for(msg_type)
    BOOTSTRAP_CLASSES[msg_type.to_sym] || msg_type
  end
end
