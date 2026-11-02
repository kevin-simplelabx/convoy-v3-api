# Correct Record: the corrected values of a past run (nil = as recorded). The run itself is not changed.
# == Schema Information
#
# Table name: occurrence_corrections
# Database name: primary
#
#  id              :bigint           not null, primary key
#  driver_name     :string
#  lock_version    :integer          default(0), not null
#  occurrence_date :date             not null
#  outcome         :string
#  vehicle_plate   :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  driver_id       :bigint
#  occurrence_id   :bigint           not null
#  vehicle_id      :bigint
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_777d975dcf  (occurrence_id,occurrence_date) UNIQUE
#  index_occurrence_corrections_on_company_id       (company_id)
#  index_occurrence_corrections_on_driver_id        (driver_id)
#  index_occurrence_corrections_on_vehicle_id       (vehicle_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (driver_id => drivers.id)
#  fk_rails_...  (vehicle_id => vehicles.id)
#
class OccurrenceCorrection < ApplicationRecord
  include TenantScoped

  OUTCOMES = %w[completed incomplete].freeze

  audited

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :correction
  belongs_to :vehicle, optional: true
  belongs_to :driver, optional: true
  has_many :stops, -> { order(:position) }, class_name: "OccurrenceCorrectionStop", dependent: :delete_all, inverse_of: :correction,
                   autosave: true
  has_many :logs, -> { order(:created_at) }, class_name: "OccurrenceCorrectionLog", dependent: :delete_all, inverse_of: :correction

  validates :outcome, inclusion: { in: OUTCOMES }, allow_nil: true

  def stop(position) = stops.find { |s| s.position == position }
end
