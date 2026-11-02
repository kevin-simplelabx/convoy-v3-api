# A photo the driver took on a run (part of the driver's report).
# == Schema Information
#
# Table name: occurrence_report_photos
# Database name: primary
#
#  id                          :bigint           not null, primary key
#  caption                     :string
#  image                       :string           not null
#  created_at                  :datetime         not null
#  updated_at                  :datetime         not null
#  company_id                  :bigint           not null
#  occurrence_driver_report_id :bigint           not null
#
# Indexes
#
#  index_occurrence_report_photos_on_company_id                   (company_id)
#  index_occurrence_report_photos_on_occurrence_driver_report_id  (occurrence_driver_report_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (occurrence_driver_report_id => occurrence_driver_reports.id)
#
class OccurrenceReportPhoto < ApplicationRecord
  include TenantScoped

  mount_uploader :image, ImageUploader

  belongs_to :report, class_name: "OccurrenceDriverReport", foreign_key: :occurrence_driver_report_id, inverse_of: :photos

  validates :image, presence: true
end
