# The driver's report after a run: a note and photos (from the driver app later; seeded for now).
# == Schema Information
#
# Table name: occurrence_driver_reports
# Database name: primary
#
#  id              :bigint           not null, primary key
#  driver_name     :string
#  note            :text
#  occurrence_date :date             not null
#  submitted_at    :datetime         not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  occurrence_id   :bigint           not null
#
# Indexes
#
#  idx_on_occurrence_id_occurrence_date_42a0837d73  (occurrence_id,occurrence_date) UNIQUE
#  index_occurrence_driver_reports_on_company_id    (company_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#
class OccurrenceDriverReport < ApplicationRecord
  include TenantScoped

  belongs_to :occurrence, class_name: "TripOccurrence", foreign_key: %i[occurrence_id occurrence_date], primary_key: %i[id date],
                          inverse_of: :driver_report
  has_many :photos, class_name: "OccurrenceReportPhoto", dependent: :destroy, inverse_of: :report

  validates :submitted_at, presence: true
end
