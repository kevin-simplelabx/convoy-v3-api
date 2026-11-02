# What happened at one stop of a run, by its place in travel order: arrival, departure, boardings, or skipped
# (passed with no one to pick up). No row = the stop was not served.
# == Schema Information
#
# Table name: occurrence_stop_events
# Database name: primary
#
#  id              :bigint           not null, primary key
#  alighted        :integer
#  arrived_at      :datetime
#  boarded         :integer
#  departed_at     :datetime
#  occurrence_date :date             not null
#  position        :integer          not null
#  skipped         :boolean          default(FALSE), not null
#  stop_name       :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  occurrence_id   :bigint           not null
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

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :stop_events

  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :boarded, :alighted, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true
end
