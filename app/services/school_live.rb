# School Bus › Live Ops: a school's buses for one session of a day (port of School Live Ops renderVals, from real runs):
# where each run is (points done, lateness, school ETA, GPS), the children on it (from the driver / attendant app's
# attendance and the parents' Bus Not Required), what needs attention, and one run in detail.
module SchoolLive
  SESSIONS = { "am" => "Morning Pick-up", "pm" => "Afternoon Drop-off", "asa" => "CCA Drop-off" }.freeze
  # Late from this many minutes (warning), and badly late (danger).
  LATE = [ 4, 10 ].freeze

  module_function

  # The school's runs of a day by session (am, pm, asa), with all a run needs.
  def runs(school, date)
    TripOccurrence.joins(school_route: :plan).where(school_plans: { school_id: school.id }, date:).where.not(status: LiveMap::NOT_DRIVEN)
                  .includes(:driver, :operator_driver, :stop_events, :passenger_marks, :ops_alerts, vehicle: %i[operator live_position],
                                                                                                school_route: [ :attendant, :plan, { stops: :riders } ])
                  .order(:starts_at, :id).to_a
                  .group_by { it.school_route.plan.session }
  end

  # The sessions running on the day: label, first start, last end.
  def sessions(by_session)
    SESSIONS.keys.filter_map do |k|
      list = by_session[k] or next
      { value: k, label: SESSIONS[k], starts_at: list.map(&:starts_at).min, ends_at: list.map(&:ends_at).max, runs: list.size }
    end
  end

  # The session to open: the one running now, else the next to start, else the last of the day.
  def default_session(list, now)
    (list.find { it[:starts_at] <= now && now < it[:ends_at] } || list.find { it[:starts_at] > now } || list.last)&.dig(:value)
  end

  # The children of the runs' routes (name, level) and their Bus Not Required on the day.
  def context(school, date, runs)
    rids = runs.flat_map { |o| o.school_route.stops.flat_map { |s| s.riders.map(&:rid) } }.uniq
    { names: SchoolRider.of_school_on(school, date).where(rid: rids).index_by(&:rid),
      absences: school.rider_absences.where(date:, rid: rids).index_by(&:rid) }
  end
end
