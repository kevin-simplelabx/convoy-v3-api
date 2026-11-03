# The PUDO point a rider of a school is assigned to (Stop Assignment): from the adopted AM plan, or by hand (manual,
# kept when the next AM plan is adopted). notified_at = when parents were told (Notify; recorded only for now).
# == Schema Information
#
# Table name: rider_assignments
# Database name: primary
#
#  id             :bigint           not null, primary key
#  manual         :boolean          default(FALSE), not null
#  notified_at    :timestamptz
#  rid            :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  company_id     :bigint           not null
#  school_id      :bigint           not null
#  school_plan_id :bigint
#  stop_point_id  :bigint           not null
#
# Indexes
#
#  index_rider_assignments_on_school_id_and_rid  (school_id,rid) UNIQUE
#  index_rider_assignments_on_school_plan_id     (school_plan_id)
#  index_rider_assignments_on_stop_point_id      (stop_point_id)
#
# Foreign Keys
#
#  fk_rails_...  (company_id => companies.id)
#  fk_rails_...  (school_id => schools.id)
#  fk_rails_...  (school_plan_id => school_plans.id) ON DELETE => nullify
#  fk_rails_...  (stop_point_id => stop_points.id) ON DELETE => cascade
#
class RiderAssignment < ApplicationRecord
  include TenantScoped
  audited associated_with: :school

  belongs_to :school
  belongs_to :stop_point
  belongs_to :school_plan, optional: true

  validates :rid, presence: true, uniqueness: { scope: :school_id }
end
