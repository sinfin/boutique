# frozen_string_literal: true

require "test_helper"

class Boutique::Ui::GiftIconCellTest < Cell::TestCase
  test "show" do
    html = cell("boutique/ui/gift_icon", nil).(:show)
    assert html.has_css?(".b-ui-gift-icon")
  end
end
