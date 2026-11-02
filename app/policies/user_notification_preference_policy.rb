# Each user reads and changes their own notification picks (Convoy Admin too: it is not company data).
class UserNotificationPreferencePolicy < ApplicationPolicy
  def show? = record.user_id == user.id
  def update? = show?
  def seen? = show?
end
