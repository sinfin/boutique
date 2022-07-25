# frozen_string_literal: true

require "test_helper"

class Folio::Console::Boutique::VatRatesControllerTest < Folio::Console::BaseControllerTest
  test "index" do
    get url_for([:console, Boutique::VatRate])

    assert_response :success

    create(:boutique_vat_rate)

    get url_for([:console, Boutique::VatRate])

    assert_response :success
  end

  test "new" do
    get url_for([:console, Boutique::VatRate, action: :new])

    assert_response :success
  end

  test "edit" do
    model = create(:boutique_vat_rate)

    get url_for([:edit, :console, model])

    assert_response :success
  end

  test "create" do
    params = build(:boutique_vat_rate).serializable_hash

    assert_difference("Boutique::VatRate.count", 1) do
      post url_for([:console, Boutique::VatRate]), params: {
        vat_rate: params,
      }
    end
  end

  test "update" do
    model = create(:boutique_vat_rate)
    assert_not_equal("Title", model.title)

    put url_for([:console, model]), params: {
      vat_rate: {
        title: "Title",
      },
    }

    assert_redirected_to url_for([:edit, :console, model])
    assert_equal("Title", model.reload.title)
  end

  test "destroy" do
    model = create(:boutique_vat_rate)

    delete url_for([:console, model])

    assert_redirected_to url_for([:console, Boutique::VatRate])
    assert_not(Boutique::VatRate.exists?(id: model.id))
  end
end
