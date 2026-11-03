# What happened at one stop of a run, by its place in travel order: arrival, departure, boardings, or skipped
# (passed with no one to pick up). No row = the stop was not served.
# == Schema Information
#
# Table name: occurrence_stop_events
# Database name: primary
#
#  id                  :bigint           not null, primary key
#  alighted            :integer
#  arrived_at          :datetime
#  boarded             :integer
#  departed_at         :datetime
#  geofence_entered_at :datetime
#  geofence_exited_at  :datetime
#  left_early_missing  :integer
#  occurrence_date     :date             not null
#  on_board            :integer
#  planned_skip        :boolean          default(FALSE), not null
#  position            :integer          not null
#  skip_reason         :string
#  skipped             :boolean          default(FALSE), not null
#  skipped_by          :string
#  source              :string           default("telematics"), not null
#  stop_name           :string
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  company_id          :bigint           not null
#  occurrence_id       :bigint           not null
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_position_02f6e5902d  (occurrence_id,occurrence_date,position) UNIQUE
#  index_occurrence_stop_events_on_company_id                (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class OccurrenceStopEvent < ApplicationRecord
  include TenantScoped

  # Who skipped the point: the driver, the app because no one was riding today, or the driver before the trip (Edit Route).
  SKIPPED_BY = %w[driver auto plan].freeze
  SOURCES = %w[driver_app telematics].freeze

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :stop_events

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :boarded, :alighted, :on_board, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
  validates :skipped_by, inclusion: { in: SKIPPED_BY }, allow_nil: true
  validates :source, inclusion: { in: SOURCES }

  def reached? = skipped || arrived_at.present?
end
