# One child's attendance on one run (School Bus or School Run): not_boarding (marked before the trip), boarded,
# not_boarded (not at the stop), alighted; how and where they boarded and alighted, and who marked it (the driver in the
# Convoy Driver app, or the office in the Scheduler's Passenger List). passenger_key = the School Bus rid, or the School
# Run route list's student key. No row = expected (or Bus Not Required from the parent, which lives in school_rider_absences).
# == Schema Information
#
# Table name: occurrence_passengers
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
#  name            :string
#  occurrence_date :date             not null
#  passenger_key   :string           not null
#  source          :string           default("driver_app"), not null
#  state           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  occurrence_id   :bigint           not null
#
# Indexes
#
#  index_occurrence_passengers_on_run_and_key  (occurrence_id,occurrence_date,passenger_key) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class OccurrencePassenger < ApplicationRecord
  include TenantScoped

  STATES = %w[not_boarding boarded not_boarded alighted].freeze
  METHODS = { "tick" => "Manual", "qr" => "QR", "card" => "Card (NFC)", "palm" => "Palm" }.freeze
  SOURCES = %w[driver_app office simulator].freeze

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :passenger_marks

  validates :passenger_key, presence: true
  validates :state, inclusion: { in: STATES }
  validates :board_method, :alight_method, inclusion: { in: METHODS.keys }, allow_nil: true
  validates :source, inclusion: { in: SOURCES }
end
