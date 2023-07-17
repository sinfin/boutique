# frozen_string_literal: true

require "savon"

class Boutique::Carrier::Zasilkovna
  TRACKING_URL = "https://tracking.packeta.com/cs_CZ/?id={TRACKING_ID}"

  # TODO: regularly check and update via the Zasilkovna API
  HOME_DELIVERY_CARRIER_ID = 106

  class Error < StandardError
    def initialize(data)
      @data = data
    end

    def to_s
      @data.to_s
    end

    def message
      m = @data[:fault][:faultstring]
      m = m.gsub("See detail.", @data[:fault][:detail].to_s)
      m
    end
  end

  def initialize
    @api_password = ENV["ZASILKOVNA_API_PASSWORD"]

    @client = Savon.client(
      wsdl: "https://www.zasilkovna.cz/api/soap.wsdl",
      endpoint: "https://www.zasilkovna.cz/api/soap",
    )
  end

  def register!(order, home_delivery: false)
    email = Rails.env.production? ? order.recipient_email : "test@test.test"
    address = if home_delivery
      {
        addressId: HOME_DELIVERY_CARRIER_ID,
        street: order.primary_address.address_line_1,
        houseNumber: order.primary_address.address_line_2,
        city: order.primary_address.city,
        zip: order.primary_address.zip,
      }
    else
      {
        addressId: order.pickup_point_remote_id
      }
    end

    data = {
      attributes: {
        number: order.number,
        name: order.recipient_first_name,
        surname: order.recipient_last_name,
        email:,
        phone: order.primary_address.try(:phone).try(:strip),
        value: order.line_items_price,
        currency: order.currency,
        weight: order.line_items.sum(&:weight),
      }.merge(address)
    }

    response = call(:create_packet, data)
    result = response.body[:create_packet_response][:create_packet_result]

    order.update!(package_remote_id: result[:id],
                  package_tracking_id: result[:barcode])
    order
  end

  def get_pdf_label(order)
    data = {
      packetId: order.package_remote_id,
      format: "A7 on A7",
      offset: 0
    }
    response = call(:packet_label_pdf, data)

    file_content = response.body[:packet_label_pdf_response][:packet_label_pdf_result]
    Base64.decode64(file_content).force_encoding("utf-8")
  end

  private
    def call(action, data)
      message = data.merge(apiPassword: @api_password)
      @client.call(action, message:)
    rescue Savon::SOAPFault => error
      raise Error.new(error.to_hash)
    end
end
