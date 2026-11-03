# A rider (school + student ID) of a family; one family per rider at a school. applied / accepted = from the Convoy App.
# == Schema Information
#
# Table name: family_riders
# Database name: primary
#
#  id          :bigint           not null, primary key
#  accepted_at :timestamptz
#  applied_at  :timestamptz
#  rid         :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :bigint           not null
#  family_id   :bigint           not null
#  school_id   :bigint           not null
#
# Indexes
#
#  index_family_riders_on_family_id          (family_id)
#  index_family_riders_on_school_id_and_rid  (school_id,rid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (family_id => families.id) ON DELETE => cascade
#  fk_rails_...  (school_id => schools.id)
#
class FamilyRider < ApplicationRecord
  include TenantScoped
  audited associated_with: :family

  belongs_to :family
  belongs_to :school

  validates :rid, presence: true, uniqueness: { scope: :school_id, message: "is already in a family at this school" }
end
