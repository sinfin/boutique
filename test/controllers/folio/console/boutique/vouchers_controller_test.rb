# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::VouchersControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Boutique::Voucher])

    assert_response :success

    create(:boutique_voucher)

    get url_for([:console, Boutique::Voucher])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Boutique::Voucher, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:boutique_voucher)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:boutique_voucher).serializable_hash

    assert_difference("Boutique::Voucher.count", 1) do
      post url_for([:console, Boutique::Voucher]), params: {
        voucher: params,
      }
    end

    assert_difference("Boutique::Voucher.count", 2) do
      post url_for([:console, Boutique::Voucher]), params: {
        voucher: params.merge(quantity: 2),
      }
    end
  end

  test "update" do
    model = create(:boutique_voucher)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      voucher: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:boutique_voucher)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Boutique::Voucher])
    assert_not(Boutique::Voucher.exists?(id: model.id))
  end
end
