# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::SubscriptionsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Boutique::Subscription])

    assert_response :success

    create(:boutique_subscription)

    get url_for([:console, Boutique::Subscription])

    assert_response :success
  end

  # test "new" do
  #   get url_for([:console, @user, action: :new])
  #   assert_response :success
  # end
  #
  # test "create" do
  #   assert_difference("@user.subscriptions.count", 1) do
  #     post url_for([:console, @user, Boutique::Subscription]), params: {
  #       subscription: {
  #         boutique_product_variant_id: create(:boutique_product_subscription).master_variant.id,
  #         active_from: 1.month.ago,
  #         active_until: 1.month.from_now,
  #         primary_address_attributes: build(:folio_address_primary).serializable_hash,
  #       },
  #     }
  #   end
  #
  #   assert_redirected_to url_for([:console, @user])
  # end
  #
  # test "edit" do
  #   @model = create(:boutique_subscription, user: @user)
  #
  #   get url_for([:edit, :console, @user, @model])
  #   assert_response :success
  # end
  #
  # test "update" do
  #   @model = create(:boutique_subscription, user: @user)
  #
  #   target_active_until = 2.years.from_now.round
  #   assert_not_equal target_active_until, @model.active_until
  #
  #   put url_for([:console, @user, @model]), params: {
  #     subscription: {
  #       active_until: target_active_until,
  #     },
  #   }
  #
  #   assert_redirected_to url_for([:console, @user])
  #   assert_equal target_active_until, @model.reload.active_until
  # end

  test "cancel" do
    @model = create(:boutique_subscription)

    assert_not @model.cancelled_at?
    delete url_for([:cancel, :console, @model])
    assert_redirected_to url_for([:console, @model])
    assert @model.reload.cancelled_at?
  end
end
