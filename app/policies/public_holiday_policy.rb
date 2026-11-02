class PublicHolidayPolicy < ApplicationPolicy
  def import? = write?
end
