# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::ShippingMethodsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Boutique::ShippingMethod])

    assert_response :success

    create(:boutique_shipping_method)

    get url_for([:console, Boutique::ShippingMethod])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Boutique::ShippingMethod, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:boutique_shipping_method)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:boutique_shipping_method).serializable_hash

    assert_difference("Boutique::ShippingMethod.count", 1) do
      post url_for([:console, Boutique::ShippingMethod]), params: {
        shipping_method: params,
      }
    end
  end

  test "update" do
    model = create(:boutique_shipping_method)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      shipping_method: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:boutique_shipping_method)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Boutique::ShippingMethod])
    assert_not(Boutique::ShippingMethod.exists?(id: model.id))
  end
end
