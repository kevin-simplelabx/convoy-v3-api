# Replacements: any company user may make them from the Scheduler (Convoy Admin views only).
class ReplacementPolicy < ApplicationPolicy
  def preview? = true
end
