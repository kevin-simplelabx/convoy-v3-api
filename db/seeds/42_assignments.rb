# Assign page samples: Hup Seng runs bus 2 of the MBC Campus Shuttle for an agreed monthly pay, and the Cross-site
# Shuttle moves to an own bus from next week.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  mbc = Trip.kept.find_by!(label: "seed-mbc-shuttle")
  cross = Trip.kept.find_by!(label: "seed-cross-site")

  if mbc.assignments.none?
    Assignments::Create.call(
      trip: mbc, effective_from: mbc.starts_on, slots: mbc.runs.map { |r| [ r.id, 2 ] }, assignee: "operator", user: admin,
      operator: Operator.find_by!(name: "Hup Seng Coaches"), vehicle: Vehicle.kept.find_by!(plate: "PC7475L"),
      pay_amount: 4500, pay_basis: "month"
    )
  end

  # The outbound runs move; the 12:00 return stays with PD4472H (Lee Kok Wah's shuttle in the Driver app, all year).
  if cross.assignments.none?
    Assignments::Create.call(
      trip: cross, effective_from: Date.current.next_occurring(:monday) + 7, slots: cross.runs.select { it.direction == 1 }.map { |r| [ r.id, 1 ] },
      assignee: "own", vehicle: Vehicle.kept.find_by!(plate: "PD5126A"), user: admin
    )
  end

  # A database seeded when the move took every run: the return goes back to PD4472H from today.
  back = cross.runs.find { it.direction == 2 }
  lee_bus = Vehicle.kept.find_by!(plate: "PD4472H")
  next_back = back && TripOccurrence.where(trip_run_id: back.id, slot_no: 1, date: Date.current..).where.not(status: "removed").order(:date).first
  if next_back && (next_back.original_vehicle_id || next_back.vehicle_id) != lee_bus.id
    Assignments::Create.call(trip: cross, effective_from: Date.current, slots: [ [ back.id, 1 ] ], assignee: "own", vehicle: lee_bus, user: admin)
  end
end
