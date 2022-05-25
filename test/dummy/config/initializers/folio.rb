# frozen_string_literal: true

Rails.application.config.folio_image_spacer_background_fallback = true

Rails.application.config.folio_console_sidebar_prepended_link_class_names = [{ links: %w[
  Boutique::Product
  Boutique::Order
  Boutique::Voucher
] }]
