# School Bus academic years (Terms & Semesters, Holidays & Special Days).
module AcademicYears
  module_function

  # The School Bus runs of a school follow its calendar: re-sync its routes in the background after a change.
  def resync(school)
    routes = SchoolRoute.joins(:plan).where(school_plans: { school_id: school.id }).where(id: SchoolRoutes.running_ids).pluck(:id)
    OccurrenceSyncJob.perform_later(school.company_id, [], Date.current.iso8601, nil, routes) if routes.any?
  end
end
