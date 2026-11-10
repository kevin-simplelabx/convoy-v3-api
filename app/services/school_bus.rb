# School Bus service: the bus types of the routing engine (Convoy Pathfinder) with their seats and whether the law
# requires a bus attendant on them.
module SchoolBus
  BUS_TYPES = {
    "LARGE_45" => { label: "45-seater", seats: 45, law: true }, "LARGE_40" => { label: "40-seater", seats: 40, law: true },
    "MEDIUM_23" => { label: "23-seater", seats: 23, law: false }, "SMALL_13" => { label: "13-seater", seats: 13, law: false },
    "SMALL_9" => { label: "9-seater", seats: 9, law: false }
  }.freeze

  module_function

  def statutory_sizes = BUS_TYPES.select { |_, t| t[:law] }.keys

  # The bus types for a school's money screens: seats, and student seats = seats less the attendant's seat on the sizes
  # the school's Bus Attendant setting needs one on (the engine's prepTypes).
  def types(school)
    needed = (school.attendant_policy || SchoolAttendantPolicy.new).needed_sizes
    BUS_TYPES.map { |k, t| { key: k, label: t[:label], seats: t[:seats], student_seats: t[:seats] - (needed.include?(k) ? 1 : 0) } }
  end

  # Runs per bus type in the AM and PM route plans in use today (HTML planBuses: an AM and a PM run count as 2), for
  # per-bus fares "From Route Plans". Routes without a bus type are left out.
  def plan_runs(school, day = Date.current)
    SchoolRoute.joins(:plan).merge(SchoolDashboard.plans_on(school, day).where(session: %w[am pm])).where.not(bus_type: nil).group(:bus_type).count
  end
end
