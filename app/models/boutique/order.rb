# frozen_string_literal: true

class Boutique::Order < Boutique::ApplicationRecord
  include AASM
  include Folio::HasAddresses
  include Folio::HasSecretHash

  EVENT_CALLBACKS = %i[before_confirm
                       after_confirm
                       before_pay
                       after_pay]

  belongs_to :user, class_name: "Folio::User",
                    foreign_key: :folio_user_id,
                    inverse_of: :orders,
                    optional: true

  belongs_to :site, class_name: "Folio::Site",
                    optional: true

  belongs_to :subscription, class_name: "Boutique::Subscription",
                            foreign_key: :boutique_subscription_id,
                            inverse_of: :orders,
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

  attr_accessor :force_address_validation

  has_many :payments, -> { ordered },
                      class_name: "Boutique::Payment",
                      foreign_key: :boutique_order_id,
                      dependent: :destroy,
                      inverse_of: :order

  has_one :paid_payment, -> { paid },
                         class_name: "Boutique::Payment",
                         foreign_key: :boutique_order_id

  scope :ordered, -> { order(base_number: :desc, id: :desc) }
  scope :except_pending, -> { where.not(aasm_state: "pending") }
  scope :except_subsequent, -> { where(original_payment_id: nil) }

  scope :ordered_by_line_items_price_asc, -> {
    order(line_items_price: :asc)
  }

  scope :ordered_by_line_items_price_desc, -> {
    order(line_items_price: :desc)
  }

  scope :by_state, -> (state) { where(aasm_state: state) }

  scope :by_number_query, -> (q) {
    where("number ILIKE ?", "%#{q}%")
  }

  scope :by_address_identification_number_query, -> (q) {
    subselect = Folio::Address::Base.where("identification_number LIKE ?", "%#{q}%").select(:id)
    where(primary_address_id: subselect).or(where(secondary_address_id: subselect))
  }

  scope :by_confirmed_at_range, -> (range_str) {
    from, to = range_str.split(/ ?- ?/)
    if to
      to = "#{to} 23:59" if from == to && to.exclude?(":")
      from_date_time = DateTime.parse(from)
      to_date_time = DateTime.parse(to)
      where("confirmed_at >= ?", from_date_time).where("confirmed_at <= ?", to_date_time)
    else
      from_date_time = DateTime.parse(from)
      where("confirmed_at >= ?", from_date_time)
    end
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

  scope :by_line_items_price_range_from, -> (line_items_price) {
    where.not(line_items_price: nil).where("line_items_price >= ?", line_items_price)
  }

  scope :by_line_items_price_range_to, -> (line_items_price) {
    where.not(line_items_price: nil).where("line_items_price <= ?", line_items_price)
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
            :first_name,
            :last_name,
            :base_number,
            :number,
            :line_items,
            presence: true,
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

  validates :gift_recipient_email,
            :gift_recipient_notification_scheduled_for,
            presence: true,
            if: -> { gift? && !pending? }

  validates :gift_recipient_email,
            format: { with: Folio::EMAIL_REGEXP },
            if: -> { gift? && !pending? },
            allow_nil: true

  validate :validate_gift_address, if: -> { gift? && !pending? }

  has_sanitized_fields :first_name,
                       :last_name,
                       :email,
                       :gift_recipient_email

  aasm timestamps: true do
    state :pending, initial: true
    state :confirmed, color: "red"
    state :waiting_for_offline_payment, color: "red"
    state :paid, color: "yellow"
    state :dispatched, color: "green"
    state :cancelled, color: "dark"

    states = Boutique::Order.aasm.states.map(&:name)

    event :confirm, private: true do
      transitions from: :pending, to: :confirmed

      before do
        set_numbers
        imprint_prices
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

      before do
        set_invoice_number

        before_pay
      end

      after do
        if subsequent?
          subscription.prolong!
        else
          invite_user!
          set_up_subscription! unless gift? || subsequent?
        end

        after_pay
      end

      after_commit do
        if subsequent?
          Boutique::OrderMailer.paid_subsequent(self).deliver_later
        else
          Boutique::OrderMailer.paid(self).deliver_later
        end
      end
    end

    event :dispatch do
      transitions from: :paid, to: :dispatched
    end

    event :cancel do
      transitions from: states.without(:cancelled), to: :cancelled
    end

    event :revert_cancelation do
      transitions from: :cancelled, to: :dispatched, guard: :dispatched_at?
      transitions from: :cancelled, to: :paid, guard: :paid_at?
      transitions from: :cancelled, to: :confirmed, guard: :confirmed_at?
      transitions from: :cancelled, to: :pending

      before { self.cancelled_at = nil }
    end
  end

  EVENT_CALLBACKS.each do |cb|
    define_method cb do
      # override in main app if needed
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

  def line_items_price
    super || line_items.sum(&:price)
  end

  def discount
    super || begin
      return 0 unless voucher.present? &&
                      voucher.applicable?

      if voucher.discount_in_percentages?
        line_items_price * (0.01 * voucher.discount)
      else
        voucher.discount
      end
    end
  end

  def total_price
    super || [line_items_price - discount.to_i, 0].max
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

  def add_line_item!(product_variant, amount: 1)
    subscription_recurring = product_variant.product.subscription? &&
                             product_variant.product.subscription_recurrent_payment_enabled?

    Boutique::Order.transaction do
      if ::Boutique.config.use_cart_in_orders
        if line_item = line_items.all.find { |li| li.boutique_product_variant_id == product_variant.id }
          line_item.amount += amount
          line_item.save!
        else
          line_items.build(product_variant:,
                           subscription_recurring:,
                           amount:)
        end
      else
        # TODO: add line item count validation
        if line_item = line_items.first
          line_item.update!(product_variant:,
                            subscription_recurring:,
                            amount:)

          if voucher.present? && !voucher.relevant_for?(product_variant)
            # TODO: show message that voucher has been removed
            self.voucher = nil
            self.voucher_code = nil
          end
        else
          line_items.build(product_variant:,
                           subscription_recurring:,
                           amount:)
        end
      end

      self.site = product_variant.product.site

      save!
    end
  end

  def assign_voucher_by_code(code)
    self.voucher_code = code
    validate_voucher_code(ignore_blank: false)
    save(validate: false) if errors.empty?
  end

  def digital_only?
    line_items.all?(&:digital_only?)
  end

  def subsequent?
    original_payment_id?
  end

  def checkout_title
    line_items.first.try(:product_variant).try(:title).presence || self.class.model_name.human
  end

  def invoice_note
    nil
  end

  def charge_recurrent_payment!
    return unless confirmed? && subsequent?

    begin
      payment = Boutique::GoPay::Api.new.create_recurrent_payment(self)
      payments.create!(remote_id: payment["id"],
                       payment_method: payment["payment_instrument"])
    rescue GoPay::Error => error
      if error.body["errors"].any? { |e| e["error_code"] == 342 }
        # 342: PAYMENT_RECURRENCE_STOPPED
        # cancel subscription if recurrence was stopped in GoPay admin
        subscription.cancel!
      else
        raise error
      end
    end
  end

  def deliver_gift!
    return unless gift?

    gift_recipient_user = Folio::User.find_by(email: gift_recipient_email) || begin
      gift_recipient_first_name, gift_recipient_last_name = primary_address.name.split(" ", 2)

      Folio::User.invite!(email: gift_recipient_email,
                          first_name: gift_recipient_first_name,
                          last_name: gift_recipient_last_name,
                          primary_address: primary_address.try(:dup)) do |u|
        u.skip_invitation = true
      end
    end

    set_up_subscription!(recipient: gift_recipient_user)

    Boutique::OrderMailer.gift_notification(self, gift_recipient_user.raw_invitation_token).deliver_later
  end

  def requires_address?
    !digital_only?
  end

  def requires_address_and_not_pending?
    requires_address? && !pending?
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

  private
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

    def set_invoice_number
      return if invoice_number.present?

      self.paid_at = current_time_from_proper_timezone

      if Boutique.config.invoice_number_with_year_prefix
        unless Boutique::Order.where("paid_at >= ?", paid_at.beginning_of_year).exists?
          Boutique::Order.connection.execute("ALTER SEQUENCE boutique_orders_invoice_base_number_seq RESTART;")
        end
        year_prefix = paid_at.year.to_s.last(2)
      end

      invoice_number_base = ActiveRecord::Base.nextval("boutique_orders_invoice_base_number_seq")

      self.invoice_number = [
        invoice_number_prefix,
        year_prefix,
        invoice_number_base.to_s.rjust(Boutique.config.invoice_number_base_length, "0")
      ].compact.join
    end

    def invite_user!
      return unless user.nil?

      self.user = Folio::User.invite!(email:,
                                      first_name:,
                                      last_name:,
                                      use_secondary_address:,
                                      primary_address: primary_address.try(:dup),
                                      secondary_address: secondary_address.try(:dup))

      update_columns(folio_user_id: user.id,
                     updated_at: current_time_from_proper_timezone)
    end

    def set_up_subscription!(recipient: nil)
      li = line_items.select(&:subscription?)

      return if li.empty?

      fail "multiple subscriptions in one order are not implemented" if li.size > 1

      line_item = li.first
      period = 12
      active_from = line_item.subscription_starts_at || gift_recipient_notification_scheduled_for || paid_at
      cancelled_at = active_from unless line_item.subscription_recurring?

      create_subscription!(payment: paid_payment,
                           product_variant: line_item.product_variant,
                           user: recipient || user,
                           period:,
                           active_from:,
                           active_until: active_from + period.months,
                           cancelled_at:)
    end

    def set_site
      self.site ||= line_items.first.product_variant.product.site if line_items.present?
    end

    def use_voucher!
      # TODO: make this work with multiple line items
      voucher.use! if voucher.try(:applicable_for?, line_items.first.product_variant)
    end

    def apply_voucher
      return unless voucher.present? &&
                    voucher.applicable_for?(line_items.first.product_variant)

      self.discount = if voucher.discount_in_percentages?
        price * (0.01 * voucher.discount)
      else
        voucher.discount
      end
    end

    def imprint_prices
      line_items.each { |li| li.imprint! }

      self.line_items_price = line_items_price
      self.discount = discount
      self.total_price = total_price
    end

    def validate_voucher_code(ignore_blank: true)
      return unless pending? || aasm.from_state == :pending

      if voucher_code.blank?
        errors.add(:voucher_code, :blank) unless ignore_blank
      else
        found_voucher = Boutique::Voucher.find_by_token_case_insensitive(voucher_code)

        if found_voucher.nil? || found_voucher.used_up?
          errors.add(:voucher_code, :invalid)
        elsif !found_voucher.published?
          errors.add(:voucher_code, :expired)
        elsif !found_voucher.relevant_for?(line_items.first.product_variant)
          errors.add(:voucher_code, :not_applicable_for)
        end

        if errors[:voucher_code].empty?
          self.voucher = found_voucher
        else
          self.voucher = nil
        end
      end
    end

    def should_validate_address?
      force_address_validation || requires_address_and_not_pending?
    end

    def validate_email_not_already_registered
      return if email.nil?
      return if user.present?

      if Folio::User.where(email:).exists?
        errors.add(:email, :already_registered)
      end
    end

    def validate_gift_address
      if primary_address.present?
        primary_address.errors.add(:name, :blank) unless primary_address.name.present?
      end
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
#
# Indexes
#
#  index_boutique_orders_on_boutique_subscription_id  (boutique_subscription_id)
#  index_boutique_orders_on_boutique_voucher_id       (boutique_voucher_id)
#  index_boutique_orders_on_folio_user_id             (folio_user_id)
#  index_boutique_orders_on_number                    (number)
#  index_boutique_orders_on_original_payment_id       (original_payment_id)
#  index_boutique_orders_on_site_id                   (site_id)
#  index_boutique_orders_on_web_session_id            (web_session_id)
#
# Foreign Keys
#
#  fk_rails_...  (boutique_subscription_id => boutique_subscriptions.id)
#  fk_rails_...  (boutique_voucher_id => boutique_vouchers.id)
#  fk_rails_...  (folio_user_id => folio_users.id)
#
