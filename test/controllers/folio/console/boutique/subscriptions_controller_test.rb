# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::SubscriptionsControllerTest < Folio::Console::BaseControllerTest
  def setup
    super
    @model = create(:boutique_subscription)
  end

  test "edit" do
    get url_for([:edit, :console, @model.user, @model])
    assert_response :success
  end

  test "update" do
    target_active_until = 2.years.from_now.round
    assert_not_equal target_active_until, @model.active_until

    put url_for([:console, @model.user, @model]), params: {
      subscription: {
        active_until: target_active_until,
      },
    }

    assert_redirected_to url_for([:console, @model.user])
    assert_equal target_active_until, @model.reload.active_until
  end

  test "cancel" do
    assert_not @model.cancelled_at?
    delete url_for([:cancel, :console, @model.user, @model])
    assert_redirected_to url_for([:console, @model.user])
    assert @model.reload.cancelled_at?
  end
end
