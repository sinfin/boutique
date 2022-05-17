# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::ProductsControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Boutique::Product])

    assert_response :success

    create(:boutique_product)

    get url_for([:console, Boutique::Product])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Boutique::Product, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:boutique_product)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:boutique_product).serializable_hash.merge("type" => "Boutique::Product::Basic",
                                                              "variants_attributes" => {
      "1" => build(:boutique_product_variant, regular_price: 150, master: true).serializable_hash
    })

    assert_difference("Boutique::Product.count", 1) do
      post url_for([:console, Boutique::Product]), params: {
        product: params,
      }
    end
  end

  test "update" do
    model = create(:boutique_product)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      product: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:boutique_product)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Boutique::Product])
    assert_not(Boutique::Product.exists?(id: model.id))
  end
end
