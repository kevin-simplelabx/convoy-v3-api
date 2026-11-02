# Maintenance: any company user may plan and record visits (the Scheduler toolbar and empty slots open it).
class MaintenanceVisitPolicy < ApplicationPolicy
  def cancel? = write? && record.scheduled?
end
