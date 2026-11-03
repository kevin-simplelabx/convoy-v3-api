# Convoy Admin > Discover > a placement in the Convoy App: a bookable trip, a programme or event, an advert or offer,
# or Convoy's own news. Shown on Home and / or the Discover tab (and pushed once) to some audiences in an area, from
# starts_on to ends_on. State today: draft, scheduled, live, paused or ended (status_on). Publishing checks what the
# app needs to sell it.
# == Schema Information
#
# Table name: discover_placements
# Database name: primary
#
#  id                     :bigint           not null, primary key
#  area                   :string           default("all"), not null
#  audiences              :string           default(["parents"]), not null, is an Array
#  background             :string           default("#004F59"), not null
#  bus_included           :boolean          default(TRUE), not null
#  child_price            :decimal(12, 2)
#  commission_pct         :decimal(5, 2)    default(0.0), not null
#  cta                    :string           default("Book Now"), not null
#  ended_at               :datetime
#  ends_on                :date             not null
#  event_on               :date
#  image                  :string
#  kicker                 :string
#  kind                   :string           default("trip"), not null
#  link                   :string
#  listing_fee            :decimal(12, 2)   default(0.0), not null
#  pickup_points          :string
#  price                  :decimal(12, 2)
#  promo_code             :string
#  push_once              :boolean          default(FALSE), not null
#  school_level           :string           default("any"), not null
#  seats                  :integer
#  show_discover          :boolean          default(TRUE), not null
#  show_home              :boolean          default(TRUE), not null
#  slot                   :string           default("std"), not null
#  sold                   :integer          default(0), not null
#  sold_to_public         :boolean          default(FALSE), not null
#  starts_on              :date             not null
#  status                 :string           default("draft"), not null
#  subtitle               :string
#  taps                   :integer          default(0), not null
#  title                  :string           not null
#  views                  :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  created_by_id          :bigint
#  discover_advertiser_id :bigint
#  run_by_company_id      :bigint
#
# Indexes
#
#  index_discover_placements_on_created_by_id                     (created_by_id)
#  index_discover_placements_on_discover_advertiser_id            (discover_advertiser_id)
#  index_discover_placements_on_run_by_company_id                 (run_by_company_id)
#  index_discover_placements_on_status_and_starts_on_and_ends_on  (status,starts_on,ends_on)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (discover_advertiser_id => discover_advertisers.id)
#  fk_rails_...  (run_by_company_id => companies.id)
#
class DiscoverPlacement < ApplicationRecord
  audited

  KINDS = { "trip" => "Bookable Trip", "prog" => "Programme or Event", "ad" => "Advert or Offer", "news" => "From Convoy" }.freeze
  AUDIENCES = { "parents" => "Parents", "staff" => "Shuttle Riders", "bookers" => "School and Company Bookers", "public" => "Public by Web Link" }.freeze
  AREAS = { "all" => "All Singapore", "east" => "East", "west" => "West", "north" => "North", "ne" => "North-East", "central" => "Central" }.freeze
  LEVELS = { "any" => "Any child", "pre" => "Pre-school", "primary" => "Primary", "secondary" => "Secondary" }.freeze

  mount_uploader :image, ImageUploader

  belongs_to :advertiser, class_name: "DiscoverAdvertiser", foreign_key: :discover_advertiser_id, optional: true, inverse_of: :placements
  belongs_to :run_by_company, class_name: "Company", optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :kind, KINDS.keys.index_by(&:itself), prefix: :kind, validate: true
  enum :status, { draft: "draft", live: "live", paused: "paused" }, validate: true

  normalizes :title, :kicker, :subtitle, with: ->(v) { v.to_s.squish.presence }
  normalizes :audiences, with: ->(v) { AUDIENCES.keys & Array(v).map(&:to_s) }

  validates :title, presence: { message: "Enter the title" }
  validates :background, format: { with: /\A#\h{6}\z/ }
  validates :slot, inclusion: { in: %w[std feat] }
  validates :area, inclusion: { in: AREAS.keys }
  validates :school_level, inclusion: { in: LEVELS.keys }
  validates :price, :child_price, :listing_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :commission_pct, numericality: { in: 0..100 }
  validate :publishable

  # draft | scheduled | live | paused | ended
  def status_on(today = Date.current)
    return "draft" if draft?
    return "ended" if ended_at || today > ends_on
    return "scheduled" if today < starts_on

    paused? ? "paused" : "live"
  end

  # Commission earned so far: price × sold × % (trips and programmes).
  def commission = %w[trip prog].include?(kind) ? (price.to_d * sold * commission_pct / 100).round(2) : 0.to_d

  private

  def publishable
    errors.add(:base, "Pick the advertiser") if !kind_news? && advertiser.nil?
    errors.add(:base, "Check the dates: the end is before the start") if starts_on && ends_on && ends_on < starts_on
    errors.add(:base, "Show it on Home, the Discover tab or both") unless show_home || show_discover
    errors.add(:base, "Pick who sees it") if audiences.empty?
    return if draft?

    errors.add(:base, "Enter the price") if kind_trip? && !price.to_d.positive?
    errors.add(:base, "Pick the transport company that runs the bus") if (kind_trip? || (kind_prog? && bus_included)) && run_by_company_id.nil?
    errors.add(:base, "Add a link or a promo code") if kind_ad? && link.blank? && promo_code.blank?
  end
end
