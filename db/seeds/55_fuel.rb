# Fuel & Energy: 90 days of fills for every own bus (diesel; PD5126A is electric) with odometer readings, so efficiency,
# cost per km and the vehicle cards show before real receipts arrive. A few unusual fills are acted out for Needs a
# Look: a second fill soon after another, a high price, an oversized fill and an odometer typed lower; and PD4472H
# uses about 15% more fuel in the last 60 days. Buses that already have entries are skipped.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  FuelCompany.ensure_defaults!
  fuel_cos = FuelCompany.where(kind: %w[fuel both]).to_a
  elec_co = FuelCompany.find_by!(name: "SP Mobility")
  stations = [ "Jurong West Ave 2", "Bedok North Rd", "Tampines Ave 10", "Woodlands Ave 3", "Ang Mo Kio Ave 6", "Pasir Ris Dr 3" ]
  today = Date.current

  Vehicle.kept.own.order(:plate).each_with_index do |bus, i|
    next if FuelEntry.exists?(vehicle: bus)

    elec = bus.plate == "PD5126A"
    seats = bus.seats.to_i
    km_day = seats >= 40 ? 160 : seats >= 20 ? 130 : 110
    eff = elec ? 22.0 : seats >= 40 ? 3.8 : seats >= 20 ? 6.5 : 9.0 # km/L, or kWh/100km
    tank = elec ? 80.0 : seats >= 40 ? 300.0 : seats >= 20 ? 95.0 : 70.0
    range_km = elec ? tank / eff * 100 * 0.8 : tank * eff * 0.75
    gap = [ (range_km / km_day).floor, 1 ].max
    odo = 40_000 + (i * 17_311)
    date = today - 90 + (i % gap)
    rows = []
    n = 0
    while date <= today
      km = km_day * gap * (0.9 + ((n * 7 + i) % 20) / 100.0)
      use = elec ? km * eff / 100 : km / eff
      use *= 1.15 if bus.plate == "PD4472H" && date > today - 60
      price = elec ? 0.55 : (2.62 + ((n + i) % 9) * 0.02).round(2)
      odo += km.round
      rows << { vehicle_id: bus.id, date:, time: 360 + ((n * 37 + i * 11) % 720), kind: elec ? "elec" : "diesel",
                quantity: use.round(2), cost: (use * price).round(2), odometer: odo, full: true,
                fuel_company_id: elec ? elec_co.id : fuel_cos[(n + i) % fuel_cos.size].id, station: stations[(n + i) % stations.size] }
      # AdBlue now and then on diesel coaches
      rows << rows.last.merge(kind: "def", quantity: 20, cost: 36, full: false, time: rows.last[:time] + 5) if !elec && seats >= 40 && (n % 4).zero?
      date += gap
      n += 1
    end

    # Unusual fills on three buses
    case i
    when 0
      a = rows[-3]
      rows << a.merge(date: a[:date] + 1, time: 600, quantity: (tank * 0.3).round(2), cost: (tank * 0.3 * 2.7).round(2), odometer: a[:odometer] + 40)
    when 1
      rows[-2] = rows[-2].merge(cost: (rows[-2][:quantity] * 3.45).round(2))
      rows[-4] = rows[-4].merge(quantity: (tank * 1.25).round(2), cost: (tank * 1.25 * 2.7).round(2))
    when 2
      rows[-2] = rows[-2].merge(odometer: rows[-3][:odometer] - 1_500)
    end

    now = Time.current
    FuelEntry.insert_all!(rows.map { |r| r.merge(company_id: bus.company_id, created_by_id: admin.id, created_at: now, updated_at: now) })
    FuelEntries::Recompute.call(vehicle: bus)
  end

  # Rework the derived columns (energy_km arrived later) and Needs a Look; one finding is already checked.
  Vehicle.kept.own.each { |bus| FuelEntries::Recompute.call(vehicle: bus) if FuelEntry.where(vehicle: bus, energy_km: nil).where.not(odometer: nil).count > 1 }
  FuelAlerts::Scan.call
  FuelAlert.open.where(kind: "price").first&.check!(admin) unless FuelAlert.checked.exists?
end
