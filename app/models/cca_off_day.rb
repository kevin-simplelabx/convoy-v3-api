# A day the CCA bus does not run at a school (Bus Not Running, or no school that day): every ride booked then became credit.
# == Schema Information
#
# Table name: cca_off_days
# Database name: primary
#
#  id         :bigint           not null, primary key
#  by_name    :string
#  date       :date             not null
#  reason     :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  company_id :bigint           not null
#  school_id  :bigint           not null
#  user_id    :bigint
#
# Indexes
#
#  index_cca_off_days_on_school_id_and_date  (school_id,date) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (user_id => users.id) ON DELETE => nullify
#
class CcaOffDay < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :user, optional: true

  validates :date, uniqueness: { scope: :school_id }
  validates :reason, presence: true
end
