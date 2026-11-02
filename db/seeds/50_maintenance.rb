# Workshops, a service visit tomorrow, one past visit not recorded yet (To Record), a cancelled one and recorded visits
# over the last months (parts, tyres, labour) on own buses, so the Maintenance page tabs, KPIs and spend all show data.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  shop = Workshop.find_or_create_by!(name: "Ah Huat Motor Works") { |w| w.assign_attributes(address: "21 Kaki Bukit Avenue 1, Singapore 417943", phone: "+65 6741 2233") }
  Workshop.find_or_create_by!(name: "Tyre Pro Ubi") { |w| w.assign_attributes(address: "3 Ubi Crescent, Singapore 408564", phone: "+65 6747 1100") }
  bus = Vehicle.kept.find_by!(plate: "PD1125G")
  coach = Vehicle.kept.find_by!(plate: "PD2185B")

  unless MaintenanceVisit.exists?(vehicle: bus, date: Date.current + 1)
    Maintenance::Save.call(visit: MaintenanceVisit.new, user: admin, attributes: {
      vehicle_id: bus.id, driver_id: bus.default_driver_on(Date.current + 1)&.id, date: Date.current + 1, start_time: "13:00",
      end_time: "16:00", workshop_id: shop.id, address: shop.address, kind: "service", work_to_do: "40,000 km service, check brakes"
    })
  end

  last_month = Date.current.prev_month.change(day: 12)
  unless MaintenanceVisit.exists?(vehicle: coach, date: last_month)
    Maintenance::Save.call(visit: MaintenanceVisit.new, user: admin, attributes: {
      vehicle_id: coach.id, date: last_month, start_time: "09:00", end_time: "14:00", workshop_id: shop.id, kind: "repair",
      work_to_do: "Aircon not cold, front left tyre worn", status: "completed", odometer: 182_450,
      lines_attributes: [
        { position: 0, line_type: "part", description: "Aircon compressor belt", part_number: "AC-6PK1870", brand: "Gates", quantity: 1, unit_price: 85 },
        { position: 1, line_type: "part", description: "Refrigerant R134a top up", quantity: 2, unit_price: 45 },
        { position: 2, line_type: "tyre", description: "Tyre 295/80R22.5", brand: "Bridgestone", model: "R249", tyre_position: "Front Left", quantity: 1, unit_price: 520 },
        { position: 3, line_type: "labour", description: "Labour", quantity: 3, unit_price: 60 }
      ]
    })
  end

  tyre_pro = Workshop.find_by!(name: "Tyre Pro Ubi")
  van = Vehicle.kept.find_by!(plate: "PD997M")
  coaster = Vehicle.kept.find_by!(plate: "PC8841T")
  [
    [ van, 2, 6, shop, "service", 61_200, [ [ "part", "Engine oil 5W-30", 6, 14 ], [ "part", "Oil filter", 1, 18 ], [ "labour", "Labour", 1, 60 ] ] ],
    [ coaster, 4, 20, tyre_pro, "tyres", 98_300, [ [ "tyre", "Tyre 215/75R17.5", 2, 310, "Rear Left Outer" ], [ "tyre", "Tyre 215/75R17.5", 2, 310, "Rear Right Outer" ], [ "labour", "Fitting and balancing", 1, 80 ] ] ],
    [ bus, 7, 3, shop, "inspection", 40_050, [ [ "other", "LTA inspection fee", 1, 72 ], [ "labour", "Pre-inspection check", 1, 90 ] ] ]
  ].each do |vehicle, months_ago, day, workshop, kind, odometer, lines|
    date = (Date.current << months_ago).change(day:)
    next if MaintenanceVisit.exists?(vehicle:, date:)

    Maintenance::Save.call(visit: MaintenanceVisit.new, user: admin, attributes: {
      vehicle_id: vehicle.id, date:, start_time: "09:00", end_time: "12:00", workshop_id: workshop.id, kind:, status: "completed", odometer:,
      lines_attributes: lines.each_with_index.map do |(type, desc, qty, unit, pos), i|
        { position: i, line_type: type, description: desc, quantity: qty, unit_price: unit, tyre_position: pos,
          brand: type == "tyre" ? "Michelin" : nil, model: type == "tyre" ? "XZE" : nil }
      end
    })
  end

  # Past and not recorded yet, and a cancelled one.
  [ [ coaster, Date.current - 3, "scheduled", "Brake pads squeaking" ], [ van, Date.current + 10, "cancelled", "Wipers" ] ].each do |vehicle, date, status, todo|
    next if MaintenanceVisit.exists?(vehicle:, date:)

    visit = Maintenance::Save.call(visit: MaintenanceVisit.new, user: admin, attributes: {
      vehicle_id: vehicle.id, date:, start_time: "14:00", end_time: "16:00", workshop_id: shop.id, kind: "repair", work_to_do: todo
    }).visit
    visit.update!(status:) if status == "cancelled"
  end
end
