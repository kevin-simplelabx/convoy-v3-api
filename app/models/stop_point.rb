# A PUDO point of a stop: letter A–P (shown as the stop code + letter, "BDSZ03-0001A"), spot description, used for
# pick-up / drop-off / both, bus sizes it suits (S, M, L), the primary point, where it is, a Street View link and a
# photo (the image shown, the original and the arrows / crop drawn on it, credited to who took it). A removed point is
# retired, not deleted, so its letter is not used again.
# == Schema Information
#
# Table name: stop_points
# Database name: primary
#
#  id                :bigint           not null, primary key
#  description       :string
#  lat               :decimal(10, 7)   not null
#  lng               :decimal(10, 7)   not null
#  photo             :string
#  photo_annotations :jsonb
#  photo_credit      :string
#  photo_original    :string
#  primary           :boolean          default(FALSE), not null
#  retired_at        :timestamptz
#  sizes             :string           default([]), not null, is an Array
#  street_view_url   :string
#  subzone_code      :string
#  suffix            :string           not null
#  usage             :string           default("both"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  stop_id           :bigint           not null
#
# Indexes
#
#  index_stop_points_on_stop_id_and_suffix  (stop_id,suffix) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (stop_id => stops.id) ON DELETE => cascade
#
class StopPoint < ApplicationRecord
  audited associated_with: :stop

  LETTERS = ("A".."P").to_a.freeze
  USAGES = %w[pickup dropoff both].freeze
  SIZES = { "S" => "Small", "M" => "Medium", "L" => "Large" }.freeze
  STREET_VIEW = %r{\Ahttps?://(www\.)?(google\.[a-z.]+/maps|maps\.google\.[a-z.]+|goo\.gl/maps|maps\.app\.goo\.gl)}i

  mount_uploader :photo, ImageUploader
  mount_uploader :photo_original, ImageUploader

  belongs_to :stop, inverse_of: :all_points
  has_many :photo_requests, class_name: "StopPhotoRequest", dependent: :destroy

  validates :suffix, inclusion: { in: LETTERS }
  validates :usage, inclusion: { in: USAGES }
  validates :lat, :lng, presence: true
  validate { errors.add(:base, "Point #{suffix} needs at least one bus size") if sizes.empty? }
  validate { errors.add(:sizes, "can only be S, M or L") unless (sizes - SIZES.keys).empty? }
  validate { errors.add(:base, "Street View link must be a Google Maps link") if street_view_url.present? && !street_view_url.match?(STREET_VIEW) }

  def pudo_code = "#{stop.code}#{suffix}"
end
