# frozen_string_literal: true

require "test_helper"

class Folio::Console::Wipify::OrdersControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Wipify::Order])

    assert_response :success

    create(:wipify_order, :confirmed)

    get url_for([:console, Wipify::Order])

    assert_response :success
  end

  test "edit" do
    model = create(:wipify_order, :confirmed)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "update" do
    model = create(:wipify_order)
    assert_not_equal("foo@test.test", model.email)

    put url_for([:console, model]), params: {
      order: {
        email: "foo@test.test",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("foo@test.test", model.reload.email)
  end
end
