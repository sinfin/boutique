# frozen_string_literal: true

class Boutique::Voucher < Boutique::ApplicationRecord
  include Folio::Publishable::Within

  CODE_PREFIX_MIN_LENGTH = 3
  CODE_PREFIX_MAX_LENGTH = 5
  CODE_DEFAULT_LENGTH = 10
  CODE_CHARS = ["A".."Z", "0".."9"].map(&:to_a).flatten - %w[0 1 O I L]
  CODE_TYPES = %w[custom generated]

  attribute :quantity, :integer, default: 1
  attribute :code_type, :string

  has_many :orders, class_name: "Boutique::Order",
                    foreign_key: :boutique_voucher_id,
                    dependent: :nullify,
                    inverse_of: :voucher

  scope :ordered, -> { order(id: :desc) }

  validates :code,
            :title,
            :discount,
            presence: true

  validates :code,
            uniqueness: true

  validates :code_prefix,
            length: { minimum: CODE_PREFIX_MIN_LENGTH,
                      maximum: CODE_PREFIX_MAX_LENGTH },
            allow_nil: true

  validates :discount,
            :quantity,
            numericality: { greater_than: 0 },
            allow_nil: true

  validates :discount,
            numericality: { less_than_or_equal_to: 100 },
            allow_nil: true,
            if: :discount_in_percentages

  before_validation :set_token
  before_validation :upcase_token

  def self.find_by_token_case_insensitive(code)
    find_by("upper(code) = upper(?)", code)
  end

  def use!
    increment!(:use_count)
  end

  def used_up?
    number_of_allowed_uses.present? && use_count >= number_of_allowed_uses
  end

  def upcase_token
    self.code = code.try(:upcase)
    end

  def set_token
    return if code.present? || code_type == "custom"

    c = code_prefix || ""

    loop do
      token_length = CODE_DEFAULT_LENGTH - c.length
      c += generate_token(token_length).upcase
      break unless Boutique::Voucher.where("upper(code) = ?", c).exists?
    end

    self.code = c
  end

  def generate_token(length)
    # https://gist.github.com/mbajur/2aba832a6df3fc31fe7a82d3109cb626
    Array.new(length).map { CODE_CHARS[rand(CODE_CHARS.size)] }.join
  end
end

# == Schema Information
#
# Table name: boutique_vouchers
#
#  id                      :bigint(8)        not null, primary key
#  code                    :string
#  code_prefix             :string(8)
#  title                   :string
#  discount                :integer
#  discount_in_percentages :boolean          default(FALSE)
#  number_of_allowed_uses  :integer
#  use_count               :integer          default(0)
#  published               :boolean          default(FALSE)
#  published_from          :datetime
#  published_until         :datetime
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_boutique_vouchers_on_published        (published)
#  index_boutique_vouchers_on_published_from   (published_from)
#  index_boutique_vouchers_on_published_until  (published_until)
#  index_boutique_vouchers_on_upper_code       (upper((code)::text)) UNIQUE
#
