# A stop of the company's Stop Library (School Bus): one or more PUDO points; each school that uses it has its own
# catchment (school_stops). code = "<URA subzone code>-NNNN" from the primary point's subzone, kept when points move.
# library_status: approved (every school sees it), school (only owner_school), pending (owner_school asked to add it).
# Archived (discarded) only when no school uses it.
# == Schema Information
#
# Table name: stops
# Database name: primary
#
#  id              :bigint           not null, primary key
#  code            :string           not null
#  discarded_at    :datetime
#  former_codes    :string           default([]), not null, is an Array
#  library_status  :string           default("approved"), not null
#  name            :string           not null
#  requested_at    :timestamptz
#  subzone_code    :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  created_by_id   :bigint
#  owner_school_id :bigint
#  requested_by_id :bigint
#
# Indexes
#
#  index_stops_on_company_id_and_code            (company_id,code) UNIQUE
#  index_stops_on_company_id_and_library_status  (company_id,library_status)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (owner_school_id => schools.id)
#  fk_rails_...  (requested_by_id => users.id)
#
class Stop < ApplicationRecord
  include TenantScoped
  include Discard::Model
  audited

  STATUSES = %w[approved school pending].freeze

  belongs_to :owner_school, class_name: "School", optional: true
  belongs_to :requested_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :all_points, -> { order(:suffix) }, class_name: "StopPoint", dependent: :delete_all, inverse_of: :stop
  has_many :points, -> { where(retired_at: nil).order(:suffix) }, class_name: "StopPoint", inverse_of: :stop
  has_many :school_stops, dependent: :restrict_with_error

  validates :name, :code, presence: true
  validates :code, uniqueness: { scope: :company_id }
  validates :library_status, inclusion: { in: STATUSES }

  # Stops a school may see: approved ones and its own (school-only or waiting for approval).
  scope :visible_to, ->(school) { school ? where(library_status: "approved").or(where(owner_school: school)) : where(library_status: "approved") }
  scope :search, lambda { |q|
    like = "%#{sanitize_sql_like(q.to_s.strip)}%"
    where("stops.name ILIKE :q OR stops.code ILIKE :q OR array_to_string(stops.former_codes, ' ') ILIKE :q", q: like)
      .or(where(id: StopPoint.where("CONCAT(stops.code, stop_points.suffix) ILIKE ?", like).joins(:stop).select(:stop_id)))
  }

  def primary_point = points.find(&:primary) || points.first

  # "Pick-up / Drop-off × Small / Medium / Large" and what is missing.
  def coverage
    warnings = []
    rows = { "pickup" => "pick-up", "dropoff" => "drop-off" }.map do |use, word|
      pts = points.select { it.usage == use || it.usage == "both" }
      cells = StopPoint::SIZES.to_h { |z, _| [ z, pts.select { it.sizes.include?(z) }.map(&:suffix) ] }
      if pts.empty? then warnings << "No #{word} point"
      elsif (missing = cells.select { |_, v| v.empty? }.keys).any?
        warnings << "No point serves #{missing.map { StopPoint::SIZES[it] }.join(' or ')} buses for #{word}"
      end
      { usage: use, sizes: cells, any: pts.any? }
    end
    { rows:, warnings: }
  end

  def needs_attention? = points.empty? || coverage[:warnings].any?
end
