# frozen_string_literal: true

class Boutique::Orders::Edit::GiftRecipientAddressFieldsCell < Folio::Addresses::FieldsCell
  def show
    model.object.build_primary_address if model.object.build_primary_address.nil?

    render
  end
end
