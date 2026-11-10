# When an adopted AM plan wrote its riders' PUDO points (Stop Assignment). Adopt writes them at once only when the plan
# starts today or earlier; a scheduled plan gets them from the daily job on its start day. The field is the lock: a plan
# is applied once.
class AddRidersAssignedAtToSchoolPlans < ActiveRecord::Migration[8.1]
  def change
    add_column :school_plans, :riders_assigned_at, :datetime
  end
end
