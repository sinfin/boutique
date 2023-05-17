# Setup

## Shipping orders
### Models

`Order`, `Line_Items`

`Package`, `Shipment`, `Shipping`, `Shipper`, `Provider`, `CountryShippingLink`, `LineItemPackageLink`

- Order has_many Line_items
- Order has_many shipments (ideally 1, but thre could be resend or more suppliers) . Direct association, not through line_items -> packages -> shipments.
- Shipment has_many packages (also known as master package)
- Package has_and_belongs_to_many line_items (resendpackage points to same line_item a s returned/lost package)
- Shipment belongs_to shipping (shipping method)
- Shipping belongs_to shipper and last_mile_carrier (same class as shipper) - companies doing physical delivery.
- Shipping has_and_belongs_to_many countries throug "country_shipping_link"
- Shipper belongs_to delivery provider ( shipper API or multi shipper service like ShippyPro, Balikovna)
- Shipper has_many branches
- Branch has_one address

Line items have (at least) states `%[created done]`.
Package have states `%[assembling done]`.
Shipment have shipping, address, branch, trackings.  States: `%[created assembling registering ready sent delivered cancelled returned lost]`
Shipping have country(country_shipping_link), price(country_shipping_link), wieght_range(country_shipping_link),volumetric_limits(country_shipping_link),
provider, servise_type (and published).

### Process
Order requires to select shipment before confirmation (if it is not digital_only?).
Packages are created when order is `paid!` and assigned to line_items. Shipment is marked as `assembling`.
When all package's line items are `done!`, package is also marked as `done!`.
When all packages are `done`, they are collected and assembled to final shipment "package", volumetric_check is (optionaly) done.
After that shipment is registered through provider.
Tracking_numbers are stored at shipment and used for tracking of it.

If shipment is returned or lost,  we can create new shipment with old/new packages and resend it (new tracking numbers).
Shipment stores it's states and tracking history.
