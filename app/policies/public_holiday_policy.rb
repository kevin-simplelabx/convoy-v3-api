class PublicHolidayPolicy < CalendarPolicy
  def import? = write?
end
