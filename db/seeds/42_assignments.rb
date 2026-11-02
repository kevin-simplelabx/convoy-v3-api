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

  if cross.assignments.none?
    Assignments::Create.call(
      trip: cross, effective_from: Date.current.next_occurring(:monday) + 7, slots: cross.runs.map { |r| [ r.id, 1 ] },
      assignee: "own", vehicle: Vehicle.kept.find_by!(plate: "PD5126A"), user: admin
    )
  end
end
