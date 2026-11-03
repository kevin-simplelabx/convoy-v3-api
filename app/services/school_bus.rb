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
end
