# Same Days Every Week in the Convoy App: the CCA bus weekdays (1 Mon … 5 Fri) picked for one child each week. They only
# pre-pick next week; the parent still pays to confirm. No row = off.
# == Schema Information
#
# Table name: cca_standing_days
# Database name: primary
#
#  id              :bigint           not null, primary key
#  days            :integer          default([]), not null, is an Array
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  company_id      :bigint           not null
#  family_id       :bigint           not null
#  school_id       :bigint           not null
#  school_rider_id :bigint           not null
#
# Indexes
#
#  index_cca_standing_days_on_company_id                     (company_id)
#  index_cca_standing_days_on_family_id                      (family_id)
#  index_cca_standing_days_on_family_id_and_school_rider_id  (family_id,school_rider_id) UNIQUE
#  index_cca_standing_days_on_school_id                      (school_id)
#  index_cca_standing_days_on_school_rider_id                (school_rider_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (family_id => families.id) ON DELETE => cascade
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (school_rider_id => school_riders.id) ON DELETE => cascade
#
class CcaStandingDay < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :family
  belongs_to :school_rider

  validates :days, length: { minimum: 1 }
  validate :weekdays_only

  private

  def weekdays_only
    errors.add(:days, "must be Monday to Friday") unless days.all? { (1..5).cover?(it) }
  end
end
