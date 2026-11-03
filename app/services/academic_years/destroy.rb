# Delete Year: only before the year starts; removes everything of that year (calendar, holidays, sessions, …).
module AcademicYears
  class Destroy < ApplicationService
    def initialize(year)
      @year = year
    end

    def call
      raise Error, "AY #{@year.key} has started and cannot be deleted" if @year.started?

      @year.destroy!
      AcademicYears.resync(@year.school)
    end
  end
end
