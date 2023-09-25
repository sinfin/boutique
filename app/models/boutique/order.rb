# frozen_string_literal: true

class Boutique::Order < Boutique::ApplicationRecord
  include AASM
  include Folio::HasAddresses
  include Folio::HasSecretHash

  EVENT_CALLBACKS = %i[before_confirm
                       after_confirm
                       before_pay
                       after_pay
                       after_pay_commit
                       before_dispatch
                       after_dispatch]

  MAILER_ACTIONS = %i[paid
                      paid_subsequent
                      dispatched]

  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    inverse_of: :orders,
                    optional: true

  belongs_to :gift_recipient, class_name: "Folio::User",
                              foreign_key: :gift_recipient_id,
                              optional: true

  belongs_to :site, class_name: "Folio::Site",
                    optional: true

  belongs_to :shipping_method, class_name: "Boutique::ShippingMethod",
                               inverse_of: :order,
                               optional: true

  belongs_to :subscription, class_name: "Boutique::Subscription",
                            foreign_key: :boutique_subscription_id,
                            inverse_of: :orders,
                            optional: true

  belongs_to :renewed_subscription, class_name: "Boutique::Subscription",
                                    optional: true

  belongs_to :original_payment, class_name: "Boutique::Payment",
                                foreign_key: :original_payment_id,
                                inverse_of: :subsequent_orders,
                                optional: true

  belongs_to :voucher, class_name: "Boutique::Voucher",
                       foreign_key: :boutique_voucher_id,
                       inverse_of: :orders,
                       optional: true

  has_many :line_items, -> { ordered },
                        class_name: "Boutique::LineItem",
                        foreign_key: :boutique_order_id,
                        counter_cache: :line_items_count,
                        dependent: :destroy,
                        inverse_of: :order

  accepts_nested_attributes_for :line_items

  has_many :payments, -> { ordered },
                      class_name: "Boutique::Payment",
                      foreign_key: :boutique_order_id,
                      dependent: :destroy,
                      inverse_of: :order

  has_one :paid_payment, -> { paid },
                         class_name: "Boutique::Payment",
                         foreign_key: :boutique_order_id

  has_many :refunds, class_name: "Boutique::OrderRefund", foreign_key: :boutique_order_id, inverse_of: :order

  scope :ordered, -> { order(confirmed_at: :desc, id: :desc) }
  scope :except_pending, -> { where.not(aasm_state: "pending") }
  scope :except_subsequent, -> { where(original_payment_id: nil) }
  scope :with_invoice, -> { where.not(invoice_number: nil) }

  scope :ordered_by_total_price_asc, -> {
    order(line_items_price: :asc)
  }

  scope :ordered_by_total_price_desc, -> {
    order(line_items_price: :desc)
  }

  scope :by_state, -> (state) { where(aasm_state: state) }

  scope :by_product_type_keyword, -> (keyword) {
    case keyword
    when "subscription"
      by_product_class(Boutique::Product::Subscription)
    when "basic"
      by_product_class(Boutique::Product::Basic)
    when nil
      all
    else
      none
    end
  }

  scope :by_number_query, -> (q) {
    where("number ILIKE ?", "%#{q}%")
  }

  scope :by_address_identification_number_query, -> (q) {
    subselect = Folio::Address::Base.where("identification_number LIKE ?", "%#{q}%").select(:id)
    where(primary_address_id: subselect).or(where(secondary_address_id: subselect))
  }

  scope :by_confirmed_at_range, -> (range_str) {
    from, to = range_str.split(/ ?- ?/)

    runner = self

    if from.present?
      from_date_time = DateTime.parse(from)
      runner = runner.where("confirmed_at >= ?", from_date_time)
    end

    if to.present?
      to = "#{to} 23:59" if to.exclude?(":")
      to_date_time = DateTime.parse(to)
      runner = runner.where("confirmed_at <= ?", to_date_time)
    end

    runner
  }

  scope :by_paid_at_range, -> (range_str) {
    from, to = range_str.split(/ ?- ?/)

    runner = self

    if from.present?
      from_date_time = DateTime.parse(from)
      runner = runner.where("paid_at >= ?", from_date_time)
    end

    if to.present?
      to = "#{to} 23:59" if to.exclude?(":")
      to_date_time = DateTime.parse(to)
      runner = runner.where("paid_at <= ?", to_date_time)
    end

    runner
  }

  scope :by_subscription_state, -> (subscription_state) {
    if subscription_state == "active"
      where(boutique_subscription_id: Boutique::Subscription.active.select(:id))
    elsif subscription_state == "inactive"
      where(boutique_subscription_id: Boutique::Subscription.inactive.select(:id))
    elsif subscription_state == "none"
      where(boutique_subscription_id: nil)
    end
  }

  scope :by_subsequent_subscription, -> (str) {
    with_subscription = where.not(boutique_subscription_id: nil)

    if str == "subsequent"
      with_subscription.where.not(original_payment_id: nil)
    elsif str == "new"
      with_subscription.where(original_payment_id: nil)
    else
      none
    end
  }

  scope :by_product_class, -> (product_class) {
    boutique_product_id = product_class.select(:id)

    product_variants_subselect = Boutique::ProductVariant.where(boutique_product_id:)
                                                         .select(:id)

    ids_subselect = Boutique::LineItem.where(boutique_product_variant_id: product_variants_subselect)
                                      .select(:boutique_order_id)

    where(id: ids_subselect)
  }

  scope :by_product_id, -> (product_id) {
    product_variants_subselect = Boutique::ProductVariant.where(boutique_product_id: product_id)
                                                         .select(:id)

    ids_subselect = Boutique::LineItem.where(boutique_product_variant_id: product_variants_subselect)
                                      .select(:boutique_order_id)

    where(id: ids_subselect)
  }

  scope :by_number_range_from, -> (number) {
    where("number::INTEGER >= ?", number)
  }

  scope :by_number_range_to, -> (number) {
    where("number::INTEGER <= ?", number)
  }

  scope :by_total_price_range_from, -> (total_price) {
    where.not(total_price: nil).where("total_price >= ?", total_price)
  }

  scope :by_total_price_range_to, -> (total_price) {
    where.not(total_price: nil).where("total_price <= ?", total_price)
  }

  scope :by_voucher_title, -> (voucher_title) {
    where(boutique_voucher_id: Boutique::Voucher.by_query(voucher_title).select(:id))
  }

  scope :by_primary_address_country_code, -> (country_code) {
    if country_code == "other"
      subselect = Folio::Address::Primary.where.not(country_code: ["CZ", "SK"]).select(:id)
      where(primary_address_id: nil).or(where(primary_address_id: subselect))
    else
      subselect = Folio::Address::Primary.where(country_code:).select(:id)
      where(primary_address_id: subselect)
    end
  }

  scope :by_non_pending_order_count_range_from, -> (order_count) {
    if order_count && (order_count.is_a?(Numeric) || (order_count.is_a?(String) && order_count.match?(/\d+/)))
      subselect = Boutique::Order.except_pending
                                 .group(:folio_user_id)
                                 .select(:folio_user_id)
                                 .having("COUNT(*) >= ?", order_count)
      where(folio_user_id: subselect)
    else
      none
    end
  }

  scope :by_non_pending_order_count_range_to, -> (order_count) {
    if order_count && (order_count.is_a?(Numeric) || (order_count.is_a?(String) && order_count.match?(/\d+/)))
      subselect = Boutique::Order.except_pending
                                 .group(:folio_user_id)
                                 .select(:folio_user_id)
                                 .having("COUNT(*) <= ?", order_count)
      where(folio_user_id: subselect)
    else
      none
    end
  }

  pg_search_scope :by_query,
                  against: %i[base_number number email first_name last_name],
                  associated_against: {
                    primary_address: %i[name company_name address_line_1 zip city],
                    secondary_address: %i[name company_name address_line_1 zip city],
                  },
                  ignoring: :accents,
                  using: { tsearch: { prefix: true } }

  validates :email,
            :base_number,
            :number,
            :line_items,
            presence: true,
            unless: :pending?

  validate :validate_line_items_subscription_recurrence,
           unless: :pending?

  validates :site,
            presence: true,
            if: -> { Boutique.config.products_belong_to_site && !pending? }

  validates :email,
            format: { with: Folio::EMAIL_REGEXP },
            unless: :pending?,
            allow_nil: true

  validate :validate_voucher_code
  validate :validate_email_not_already_registered, unless: :pending?

  validates :first_name,
            :last_name,
            :shipping_method,
            presence: true,
            if: -> { requires_address? && !pending? }

  validates :gift_recipient_email,
            presence: true,
            if: -> { gift? && !pending? }

  validate :validate_gift_recipient_notification_scheduled_for_is_in_future

  validates :gift_recipient_email,
            format: { with: Folio::EMAIL_REGEXP },
            if: -> { gift? && !pending? },
            allow_nil: true

  validates :original_payment,
            presence: true,
            allow_nil: true

  before_validation :unset_unwanted_gift_attributes
  before_validation :force_primary_address_phone_validation, unless: :pending?

  after_validation :imprint_if_valid

  attr_accessor :force_address_validation
  attr_accessor :force_gift_recipient_notification_scheduled_for_validation

  after_save :check_for_shipping_method_update

  has_sanitized_fields :first_name,
                       :last_name,
                       :email,
                       :gift_recipient_first_name,
                       :gift_recipient_last_name,
                       :gift_recipient_email

  aasm do
    state :pending, initial: true
    state :confirmed, color: "red"
    state :waiting_for_offline_payment, color: "red"
    state :paid, color: "yellow"
    state :dispatched, color: "green"
    state :cancelled, color: "dark"

    after_all_transitions :set_aasm_state_timestamp

    states = Boutique::Order.aasm.states.map(&:name)

    event :confirm, private: true do
      transitions from: :pending, to: :confirmed

      before do
        set_numbers
        set_site

        self.email ||= user.try(:email)

        before_confirm
      end

      after do
        use_voucher!
        charge_recurrent_payment! if subsequent?

        after_confirm
      end
    end

    event :wait_for_offline_payment, private: true do
      transitions from: :confirmed, to: :waiting_for_offline_payment

      after do
        invite_user!
      end
    end

    event :pay, private: true do
      transitions from: %i[confirmed waiting_for_offline_payment], to: :paid

      before do |*args|
        options = args.extract_options!

        # paid_at timestamp is needed to generate the invoice number
        set_aasm_state_timestamp(at: options[:at], state: "paid")

        set_invoice_number
        register_package

        before_pay
      end

      after do
        if subsequent?
          subscription.extend!
        # elsif (subscription = same_active_subscription).present?
        #   subscription.extend!
        else
          invite_user!
          set_up_subscription! unless subsequent?

          deliver_gift!
        end

        reduce_stock!

        after_pay
      end

      after_commit do
        if subsequent?
          mailer_paid_subsequent.deliver_later
        else
          mailer_paid.deliver_later
        end

        after_pay_commit

        dispatch! if digital_only?
      end
    end

    event :dispatch do
      transitions from: :paid, to: :dispatched

      before do
        before_dispatch
      end

      after do
        after_dispatch
      end

      after_commit do
        unless digital_only?
          mailer_dispatched.deliver_later
        end
      end
    end

    event :cancel do
      transitions from: states.without(:cancelled), to: :cancelled
      before do
        self.cancelled_at = Time.current
      end
    end

    event :revert_cancelation do
      transitions from: :cancelled, to: :dispatched, guard: :dispatched_at?
      transitions from: :cancelled, to: :paid, guard: :paid_at?
      transitions from: :cancelled, to: :confirmed, guard: :confirmed_at?
      transitions from: :cancelled, to: :pending

      before { self.cancelled_at = nil }
    end
  end

  def self.secret_hash_length
    16
  end

  def full_name
    if first_name.present? || last_name.present?
      "#{first_name} #{last_name}".strip
    else
      email
    end
  end

  def to_label
    [
      number,
      full_name,
    ].compact.join(" – ")
  end

  def recipient_email
    gift ? gift_recipient_email : email
  end

  def line_items_price
    super || line_items.sum(&:price)
  end

  def shipping_price
    super || begin
      # return 0 if digital_only?

      shipping_method.try(:price) || 0
    end
  end

  def shipping_vat_rate_value
    Boutique::VatRate.default.value
  end

  def shipping_price_vat
    (shipping_price * (shipping_vat_rate_value.to_d / (100 + shipping_vat_rate_value))).round(2).to_f
  end

  def discount
    super || begin
      if voucher.present? && voucher.applicable?
        if voucher.discount_in_percentages?
          ((total_price_without_discount) * (0.01 * voucher.discount)).floor
        else
          voucher.discount - [voucher.discount - total_price_without_discount, 0].max
        end
      else
        0
      end
    end
  end

  def total_price_without_discount
    line_items_price + shipping_price
  end

  def total_price
    super || total_price_without_discount - discount
  end

  def total_price_in_cents
    total_price * 100
  end

  def free?
    total_price.zero?
  end

  def is_paid?
    paid_at?
  end

  def is_unpaid?
    !is_paid?
  end

  def currency
    # TODO: configurable currency
    "CZK"
  end

  def currency_code
    "CZK"
  end

  def currency_unit
    "Kč"
  end

  def invoice_title
    key = free? ? "title_free" : "title"
    I18n.t("boutique.orders.invoice.#{key}", number: invoice_number)
  end

  def shipping_info
    # TODO: move to Shipping model
    line_items.first.product_variant.product.shipping_info
  end

  def add_line_item!(product_variant, amount: 1)
    raise "Amount must be an integer" unless amount.is_a?(Integer)

    li = nil

    Boutique::Order.transaction do
      before_add_line_item(product_variant)

      if product_variant.product.subscription? && li = subscription_line_item
        # only one product of subscription type is allowed in the order
        # so we override existing subscription
        li.amount = 1
        li.product_variant = product_variant
      elsif li = line_items.all.find { |li| li.boutique_product_variant_id == product_variant.id }
        # variant is already in the order, just add the required amount
        li.amount += amount
      else
        # variant isn't present in the order, add new line item
        li = line_items.build(product_variant:,
                              amount:)
      end

      li.subscription_recurring = nil
      li.subscription_period = nil

      set_default_shipping_method
      self.site = product_variant.product.site

      save!
    end

    li
  end

  def assign_voucher_by_code(code)
    self.voucher_code = code
    validate_voucher_code(ignore_blank: false)
    save(validate: false) if errors.empty?
  end

  def recurrent_payment?
    return false if voucher.present?

    li = subscription_line_item
    li.present? && li.subscription_period.nil?
  end

  def recurrent_payment_available?
    voucher.nil? && line_items.any?(&:subscription?)
  end

  def digital_only?
    line_items.all?(&:digital_only?)
  end

  def first_of_subsequent?
    line_items.any?(&:subscription_recurring?) && original_payment_id.blank?
  end

  def subsequent?
    original_payment_id.present? # this will pass even if :id leads to nonexisting payment
  end

  def giftable?
    renewed_subscription.nil?
  end

  def subscription_line_item
    line_items.find(&:subscription?)
  end

  def package_tracking_url
    shipping_method.tracking_url_for(self) if shipping_method.present?
  end

  def invoice_note
    nil
  end

  def payment_gateway
    @payment_gateway ||= Boutique::PaymentGateway.new
  end

  def charge_recurrent_payment!
    return unless confirmed? && subsequent?

    transaction = payment_gateway.repeat_recurring_transaction(self)
    payments.create!(remote_id: transaction.transaction_id,
                     amount: total_price,
                     payment_method: transaction.hash.dig(:payment, :method),
                     payment_gateway_provider: payment_gateway.provider)
  rescue StandardError => error
    if error.is_a?(Boutique::PaymentGateway::Error) && error.stopped_recurrence?
      subscription.cancel!
    else
      self.save
      report_exception(error, self)
    end
  end

  def deliver_gift!
    return unless gift?
    return if gift_recipient_notification_sent_at?
    return if gift_recipient_notification_scheduled_for.present? && gift_recipient_notification_scheduled_for > Time.current

    transaction do
      self.gift_recipient = Folio::User.find_by(email: gift_recipient_email)

      if gift_recipient.present?
        Boutique::OrderMailer.gift_notification(self).deliver_later
      else
        self.gift_recipient = Folio::User.invite!(email: gift_recipient_email,
                                                  first_name:,
                                                  last_name:,
                                                  primary_address: primary_address.try(:dup),
                                                  source_site: site) do |u|
          u.skip_invitation = true
        end

        Boutique::OrderMailer.gift_notification_with_invitation(self, gift_recipient.raw_invitation_token).deliver_later
      end

      if subscription.present?
        subscription.update_columns(folio_user_id: gift_recipient_id,
                                    updated_at: current_time_from_proper_timezone)
      end
    end

    now = current_time_from_proper_timezone
    update_columns(gift_recipient_id:,
                   gift_recipient_notification_sent_at: now,
                   updated_at: now)
  end

  def requires_address?
    !digital_only?
  end

  def self.csv_attribute_names
    %i[number email full_name line_items total_price primary_address secondary_address confirmed_at paid_at aasm_state invoice]
  end

  def csv_attributes(controller)
    self.class.csv_attribute_names.map do |attr|
      case attr
      when :full_name
        user.try(:full_name) || primary_address.try(:name)
      when :line_items
        line_items.map(&:to_console_label).join(", ")
      when :primary_address, :secondary_address
        send(attr).try(:to_label)
      when :confirmed_at, :paid_at
        t = send(attr)
        I18n.l(t, format: :console_short) if t.present?
      when :invoice
        invoice_number
      when :aasm_state
        aasm.human_state
      else
        send(attr)
      end
    end
  end

  def self.console_sidebar_count
    paid.count
  end

  def fully_paid_by_voucher?
    voucher_code.present? && total_price.zero?
  end


  private
    EVENT_CALLBACKS.each do |cb|
      define_method cb do
        # override in main app if needed
      end
    end

    MAILER_ACTIONS.each do |a|
      define_method "mailer_#{a}" do
        # override in main app if needed
        Boutique::OrderMailer.send(a, self)
      end
    end

    def check_for_shipping_method_update
      if saved_change_to_attribute?(:shipping_method_id) && is_paid?
        register_package
      end
    end

    def set_default_shipping_method
      if digital_only?
        self.shipping_method = nil
      else
        self.shipping_method ||= Boutique::ShippingMethod.published.ordered.first
      end
    end

    def set_aasm_state_timestamp(*args)
      options = args.extract_options!

      ts_setter = "#{options[:state] || aasm.to_state}_at="
      respond_to?(ts_setter) && send(ts_setter, options[:at] || Time.current)
    end

    def set_numbers
      return if base_number.present?

      year_prefix = current_time_from_proper_timezone.year.to_s.last(2)
      self.base_number = ActiveRecord::Base.nextval("boutique_orders_base_number_seq")

      # format: 2200001, 2200002 ... 2309998, 2309999
      self.number = year_prefix + base_number.to_s.rjust(5, "0")
    end

    def invoice_number_prefix
      nil
    end

    def new_invoice_number
      if Boutique.config.invoice_number_resets_each_year && !Boutique::Order.where("paid_at >= ?", paid_at.beginning_of_year).exists?
        Boutique::Order.connection.execute("ALTER SEQUENCE boutique_orders_invoice_base_number_seq RESTART;")
      end
      invoice_number_base = ActiveRecord::Base.nextval("boutique_orders_invoice_base_number_seq")

      if Boutique.config.invoice_number_with_year_prefix
        year_prefix = paid_at.year.to_s.last(2)
      end

      [
        year_prefix,
        invoice_number_prefix,
        invoice_number_base.to_s.rjust(Boutique.config.invoice_number_base_length, "0")
      ].compact.join
    end

    def register_package
      return unless shipping_method.present?

      Boutique::ShippingMethod::RegisterPackageJob.perform_later(self)
    end

    def reduce_stock!
      line_items.each do |li|
        li.product_variant.decrement!(:stock, li.amount) if li.product_variant.stock.present?
      end

      true
    end

    def set_invoice_number
      return if invoice_number.present?
      self.invoice_number = new_invoice_number
    end


    def invite_user!
      return if user.present?
      existing_user = Folio::User.find_by(email:)

      transaction do
        if existing_user.nil?
          self.user = Folio::User.invite!(email:,
                                          first_name: gift ? nil : first_name,
                                          last_name: gift ? nil : last_name,
                                          use_secondary_address:,
                                          primary_address: gift? ? nil : primary_address.try(:dup),
                                          secondary_address: secondary_address.try(:dup),
                                          source_site: site)
        else
          if existing_user.invitation_token.present? && existing_user.invitation_accepted_at.nil?
            existing_user.invite!
          end
          self.user = existing_user
        end

        update_columns(folio_user_id: user.id,
                       updated_at: current_time_from_proper_timezone)
      end
    end

    def set_up_subscription!
      li = subscription_line_item

      return if li.nil?

      period = li.subscription_period || li.product_variant.subscription_period

      if requires_address?
        address = primary_address.try(:dup)
        address.name = gift ? gift_recipient_full_name : full_name
      end

      if renewed_subscription.present?
        renewed_subscription.cancelled_at = nil if li.subscription_recurring?

        renewed_subscription.update!(payment: paid_payment,
                                     active_until: renewed_subscription.active_until + period.months,
                                     primary_address: address)
        update!(subscription: renewed_subscription)
      else
        subscriber = user unless gift?

        create_subscription!(payment: paid_payment,
                             product_variant: li.product_variant,
                             user: subscriber,
                             payer: user,
                             active_from: li.subscription_starts_at,
                             active_until: li.subscription_starts_at + period.months,
                             period:,
                             recurrent: li.subscription_recurring?,
                             primary_address: address)
      end
    end

    def set_site
      self.site ||= line_items.first.product_variant.product.site if line_items.present?
    end

    def use_voucher!
      # TODO: make this work with multiple line items
      voucher.use! if voucher.try(:applicable_for?, line_items.first.product_variant.product)
    end

    def apply_voucher
      return unless voucher.present? &&
                    voucher.applicable_for?(line_items.first.product_variant.product)

      self.discount = if voucher.discount_in_percentages?
        price * (0.01 * voucher.discount)
      else
        voucher.discount
      end
    end

    def imprint_if_valid
      return if errors.present?

      if aasm.from_state == :pending && aasm.to_state == :confirmed
        imprint
      end
    end

    def imprint
      line_items.each { |li| li.imprint }

      self.line_items_price = line_items_price
      self.shipping_price = shipping_price
      self.discount = discount
      self.total_price = total_price
    end

    def validate_voucher_code(ignore_blank: true)
      return unless pending? || aasm.from_state == :pending

      if voucher_code.blank?
        errors.add(:voucher_code, :blank) unless ignore_blank
      else
        found_voucher = accessible_vouchers.find_by_token_case_insensitive(voucher_code)

        if found_voucher.nil? || found_voucher.used_up?
          errors.add(:voucher_code, :invalid)
        elsif !found_voucher.published?
          errors.add(:voucher_code, :expired)
        elsif !found_voucher.relevant_for?(line_items.first.product_variant)
          errors.add(:voucher_code, :not_applicable_for)
        end

        if errors[:voucher_code].empty?
          self.voucher = found_voucher
          subscription_line_item&.assign_attributes(subscription_period: voucher.subscription_period,
                                                         subscription_recurring: false)
        else
          self.voucher = nil
          subscription_line_item&.assign_attributes(subscription_period: nil,
                                                    subscription_recurring: nil)
        end
      end
    end

    def before_add_line_item(product_variant)
      nil
    end

    def accessible_vouchers
      Boutique::Voucher.all
    end

    def should_validate_address?
      force_address_validation || requires_address? && !pending?
    end

    def unset_unwanted_gift_attributes
      return if pending? || gift?

      self.gift_recipient_email = nil
      self.gift_recipient_first_name = nil
      self.gift_recipient_last_name = nil
      self.gift_recipient_notification_scheduled_for = nil
    end

    def validate_email_not_already_registered
      return if email.nil?
      return if user.present?

      if Folio::User.invitation_accepted.where(email:).exists?
        errors.add(:email, :already_registered)
      end
    end

    def validate_gift_recipient_notification_scheduled_for_is_in_future
      if force_gift_recipient_notification_scheduled_for_validation &&
         gift_recipient_notification_scheduled_for &&
         gift_recipient_notification_scheduled_for <= Time.current &&
        errors.add(:gift_recipient_notification_scheduled_for, :in_the_past)
      end
    end

    def validate_line_items_subscription_recurrence
      return unless recurrent_payment_available?

      li = subscription_line_item
      if li && !li.marked_for_destruction? && li.requires_subscription_recurring? && !li.subscription_recurring? && li.subscription_period.nil?
        errors.add(:line_items, :missing_subscription_recurrence)
      end
    end

    def force_primary_address_phone_validation
      return unless requires_address?
      return unless primary_address.present?

      primary_address.force_phone_validation = true
    end
end
# == Schema Information
#
# Table name: boutique_orders
#
#  id                                        :bigint(8)        not null, primary key
#  folio_user_id                             :bigint(8)
#  web_session_id                            :string
#  base_number                               :integer
#  number                                    :string
#  secret_hash                               :string
#  email                                     :string
#  first_name                                :string
#  last_name                                 :string
#  aasm_state                                :string           default("pending")
#  line_items_count                          :integer          default(0)
#  line_items_price                          :integer
#  total_price                               :integer
#  primary_address_id                        :bigint(8)
#  secondary_address_id                      :bigint(8)
#  use_secondary_address                     :boolean          default(FALSE)
#  confirmed_at                              :datetime
#  paid_at                                   :datetime
#  dispatched_at                             :datetime
#  cancelled_at                              :datetime
#  created_at                                :datetime         not null
#  updated_at                                :datetime         not null
#  boutique_subscription_id                  :bigint(8)
#  original_payment_id                       :bigint(8)
#  discount                                  :integer
#  voucher_code                              :string
#  boutique_voucher_id                       :bigint(8)
#  invoice_number                            :string
#  gift                                      :boolean          default(FALSE)
#  gift_recipient_email                      :string
#  gift_recipient_notification_scheduled_for :datetime
#  gift_recipient_notification_sent_at       :datetime
#  gtm_data_sent_at                          :datetime
#  site_id                                   :bigint(8)
#  gift_recipient_first_name                 :string
#  gift_recipient_last_name                  :string
#  gift_recipient_id                         :bigint(8)
#  shipping_price                            :integer
#  renewed_subscription_id                   :bigint(8)
#  shipping_method_id                        :bigint(8)
#  pickup_point_remote_id                    :integer
#  pickup_point_title                        :string
#  package_remote_id                         :string
#  package_tracking_id                       :string
#
# Indexes
#
#  index_boutique_orders_on_boutique_subscription_id  (boutique_subscription_id)
#  index_boutique_orders_on_boutique_voucher_id       (boutique_voucher_id)
#  index_boutique_orders_on_confirmed_at              (confirmed_at)
#  index_boutique_orders_on_folio_user_id             (folio_user_id)
#  index_boutique_orders_on_gift_recipient_id         (gift_recipient_id)
#  index_boutique_orders_on_number                    (number)
#  index_boutique_orders_on_original_payment_id       (original_payment_id)
#  index_boutique_orders_on_renewed_subscription_id   (renewed_subscription_id)
#  index_boutique_orders_on_shipping_method_id        (shipping_method_id)
#  index_boutique_orders_on_site_id                   (site_id)
#  index_boutique_orders_on_web_session_id            (web_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_subscription_id => boutique_subscriptions.id)
#  fk_rails_...  (boutique_voucher_id => boutique_vouchers.id)
#  fk_rails_...  (folio_user_id => folio_users.id)
#  fk_rails_...  (shipping_method_id => boutique_shipping_methods.id)
#
