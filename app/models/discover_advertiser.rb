# Convoy Admin > Discover > Advertisers: who pays to be in Discover (listing fee a month, commission on sales).
# A Premier Partner shows as "From <partner>" rather than Sponsored and runs the bus for Convoy's trips first.
# == Schema Information
#
# Table name: discover_advertisers
# Database name: primary
#
#  id             :bigint           not null, primary key
#  commission_pct :decimal(5, 2)    default(0.0), not null
#  country        :string           default("SG"), not null
#  discarded_at   :datetime
#  email          :string
#  kind           :string           default("brand"), not null
#  listing_fee    :decimal(12, 2)   default(0.0), not null
#  name           :string           not null
#  premier        :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_discover_advertisers_on_name  (name) UNIQUE WHERE (discarded_at IS NULL)
#
class DiscoverAdvertiser < ApplicationRecord
  include Discard::Model
  audited

  KINDS = { "tc" => "Transport Partner", "attr" => "Attraction", "prog" => "Programme Provider", "brand" => "Brand" }.freeze

  has_many :placements, class_name: "DiscoverPlacement", dependent: :restrict_with_error

  normalizes :name, with: ->(v) { v.to_s.squish }
  normalizes :email, with: ->(v) { v.to_s.strip.downcase.presence }

  validates :name, presence: { message: "Enter the advertiser's name" }, uniqueness: { conditions: -> { kept }, case_sensitive: false }
  validates :kind, inclusion: { in: KINDS.keys }
  validates :listing_fee, numericality: { greater_than_or_equal_to: 0 }
  validates :commission_pct, numericality: { in: 0..100 }
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_nil: true
end
