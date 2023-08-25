# frozen_string_literal: true

require "test_helper"

class Boutique::Ui::VectorIconCellTest < Cell::TestCase
  test "show" do
    html = cell("boutique/ui/vector_icon", nil).(:show)
    assert_not html.has_css?(".b-ui-vector-icon")

    html = cell("boutique/ui/vector_icon", icon_name: :gift).(:show)
    assert html.has_css?(".b-ui-vector-icon")
  end
end
