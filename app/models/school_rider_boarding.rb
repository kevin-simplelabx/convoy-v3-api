# == Schema Information
#
# Table name: school_rider_boardings
# Database name: primary
#
#  id              :bigint           not null, primary key
#  alight_lat      :float
#  alight_lng      :float
#  alight_method   :string
#  alighted_at     :datetime
#  board_lat       :float
#  board_lng       :float
#  board_method    :string
#  boarded_at      :datetime
#  marked_by       :string
#  occurrence_date :date             not null
#  rid             :string           not null
#  state           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  occurrence_id   :bigint           not null
#  school_route_id :bigint           not null
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_rid_de574147e6  (occurrence_id,occurrence_date,rid) UNIQUE
#  index_school_rider_boardings_on_company_id           (company_id)
#  index_school_rider_boardings_on_school_route_id      (school_route_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_route_id => school_routes.id)
#
# A child's attendance on a School Bus run, as the driver or bus attendant marked it in the app: boarded (tick, QR pass,
# card or palm, where), alighted (at the school gate or the home stop), not boarded (not at the stop) or not boarding
# today (marked before the trip).
class SchoolRiderBoarding < ApplicationRecord
  include TenantScoped

  STATES = %w[not_boarding boarded not_boarded alighted].freeze
  METHODS = { "tick" => "Manual", "qr" => "QR", "card" => "Card (NFC)", "palm" => "Palm" }.freeze

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date], inverse_of: :boardings
  belongs_to :school_route

  validates :rid, presence: true
  validates :state, inclusion: { in: STATES }
  validates :board_method, inclusion: { in: METHODS.keys }, allow_nil: true
  validates :alight_method, inclusion: { in: METHODS.keys }, allow_nil: true
end
