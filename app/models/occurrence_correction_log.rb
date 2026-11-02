# One save of Correct Record: who, when, why and the changes ("Stop 1 arrival: N/A to 08:03").
# == Schema Information
#
# Table name: occurrence_correction_logs
# Database name: primary
#
#  id                       :bigint           not null, primary key
#  items                    :text             default([]), not null, is an Array
#  reason                   :text             not null
#  created_at               :datetime         not null
#  company_id               :bigint           not null
#  occurrence_correction_id :bigint           not null
#  user_id                  :bigint
#
# Indexes
#
#  index_occurrence_correction_logs_on_company_id                (company_id)
#  index_occurrence_correction_logs_on_occurrence_correction_id  (occurrence_correction_id)
#  index_occurrence_correction_logs_on_user_id                   (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (occurrence_correction_id => occurrence_corrections.id)
#  fk_rails_...  (user_id => users.id)
#
class OccurrenceCorrectionLog < ApplicationRecord
  include TenantScoped

  belongs_to :correction, class_name: "OccurrenceCorrection", foreign_key: :occurrence_correction_id, inverse_of: :logs
  belongs_to :user, optional: true

  validates :reason, :items, presence: true
end
