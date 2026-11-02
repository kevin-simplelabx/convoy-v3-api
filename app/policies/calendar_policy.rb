# Calendars and public holidays (Settings > Calendars, Change a Day on the Scheduler): everyone in the company reads
# them (trips follow them); users with the vehicles or finance permission change them. A calendar used by trips
# can't be deleted (checked in the controller with a message).
class CalendarPolicy < ApplicationPolicy
  private

  def write? = super && (user.can?(:vehicles) || user.can?(:finance))
end
