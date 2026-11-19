# SimpleDrive's fleet: teams, operators (managed and external), own, managed and external vehicles,
# own drivers with a default driver schedule, operator drivers and attendants.
with_company("SD") do
  teams = { "East" => "#0B6E6E", "North" => "#3267D6", "Coaches" => "#8E44AD" }.to_h do |name, color|
    [ name, VehicleTeam.find_or_create_by!(name:) { |t| t.color = color } ]
  end

  hup_seng = Operator.find_or_initialize_by(name: "Hup Seng Coaches", kind: :managed).tap do |o|
    o.update!(contact_name: "Mr Lim", phone: "+65 6123 4567", email: "ops@hupseng.sg", uen: "199801234D",
              payment_method: :bank, paynow_uen: "199801234D", bank: Bank.find_by!(key: "7171D"),
              account_number: "0721234567", account_name: "HUP SENG COACHES PTE LTD")
  end
  kallang = Operator.find_or_initialize_by(name: "Kallang Bus Charter", kind: :external).tap do |o|
    o.update!(contact_name: "Ms Tan", phone: "+65 9123 4567", payment_method: :paynow, paynow_uen: "201912345K",
              valid_until: Date.current + 30, cost_per_trip: 180, cost_per_day: 650)
  end

  # plate, seats, make, model, year, team, tags, photo, operator, driver name, driver photo
  # Ah Beng drives the 45-seater on St. Stephen's AM 2 / PM 2 (Driver app sample); PD1125G is a spare bus.
  fleet = [
    [ "PD997M",  13, "Toyota",    "HiAce Commuter", 2022, "East",    %w[VIP],        "van.png",     nil,      "Eric Pang",  "drv-2.png" ],
    [ "PC7939R", 13, "Toyota",    "HiAce Commuter", 2021, "East",    %w[Wheelchair], "hiace.png",   nil,      "Frankie Ho", "drv-3.png" ],
    [ "PE1290S", 45, "Yutong",    "ZK6107H",        2024, "Coaches", %w[Coach],      nil,           nil,      "Ah Beng",    "drv-4.png" ],
    [ "PD2185B", 49, "Scania",    "K360IB",         2020, "Coaches", %w[Coach],      "bus-1.png",   nil,      "Shao Dong",  "drv-6.png" ],
    [ "PD3318K", 13, "Toyota",    "HiAce Commuter", 2023, "East",    [],             nil,           nil,      nil,          nil ],
    [ "PD4472H", 13, "Toyota",    "HiAce Commuter", 2023, "North",   [],             nil,           nil,      nil,          nil ],
    [ "PD5126A", 13, "Toyota",    "HiAce Commuter", 2024, "North",   [],             nil,           nil,      nil,          nil ],
    [ "PC8841T", 23, "Toyota",    "Coaster",        2022, "East",    [],             nil,           nil,      nil,          nil ],
    [ "PD6604E", 40, "King Long", "XMQ6900",        2021, "Coaches", %w[Coach],      nil,           nil,      nil,          nil ],
    [ "PD1125G", 13, "Toyota",    "HiAce Commuter", 2023, "North",   [],             "minibus.png", nil,      nil,          nil ],
    [ "PC7475L", 23, "Mitsubishi", "Rosa",          2019, nil,       [],             "bus-3.png",   hup_seng, "Tony Tan",   "drv-5.png" ],
    [ "PD2030P", 40, "MAN",       "A69",            2018, nil,       %w[Coach],      "bus-2.png",   hup_seng, "Ramlee",     "drv-1.png" ],
    [ "PA1234X", 45, "Yutong",    "ZK6122H9",       2017, nil,       %w[Coach External], "bus-4.png", kallang, "Muthu",     nil ]
  ]

  phone = ->(i) { "+65 9#{format('%03d', 210 + (i * 37))} #{format('%04d', 4100 + (i * 371))}" }
  # Joined on the day first seeded (kept on later seeds), invited and answered no later than that.
  joined = lambda do |d, at|
    d.joined_at ||= at
    d.responded_at ||= d.joined_at
    d.invited_at = d.joined_at if d.invited_at.nil? || d.invited_at > d.joined_at
  end
  # The driver's default bus from `from`, once. A driver who was on another bus (a database seeded before) moves today
  # and leaves that bus without a default driver.
  default_driver = lambda do |vehicle, driver, from|
    next if vehicle.driver_schedules.exists?(driver:)

    was = driver.vehicle_on(Date.current)
    was&.driver_schedules&.find_or_create_by!(starts_on: Date.current, start_time: 0)
    vehicle.driver_schedules.create!(driver:, starts_on: was ? Date.current : from)
  end

  # A driver's mobile comes from the row: Eric Pang 0, Frankie Ho 1 and Ah Beng 2 (+65 9210 4100, 9247 4471, 9284 4842).
  fleet.each_with_index do |(plate, seats, make, model, year, team, tags, photo, operator, driver_name, driver_photo), i|
    vehicle = Vehicle.kept.find_or_initialize_by(plate:)
    vehicle.assign_attributes(seats:, make:, model:, year_made: year, vehicle_team: teams[team], tags:, operator:)
    vehicle.photo = SeedFiles.open("fleet", photo) if photo && vehicle.photo.blank?
    if operator&.external?
      vehicle.assign_attributes(driver_name:, driver_phone: phone.(i))
    end
    vehicle.save!
    next if driver_name.nil? || operator&.external?

    if operator
      driver = OperatorDriver.find_or_initialize_by(phone: OperatorDriver.normalize_value_for(:phone, phone.(i)))
      driver.assign_attributes(name: driver_name, operator:, status: :active)
      joined.(driver, 3.months.ago)
      driver.photo = SeedFiles.open("fleet", driver_photo) if driver_photo && driver.photo.blank?
      driver.save!
      driver.assign_vehicle!(vehicle) unless driver.vehicle_id == vehicle.id
    else
      driver = Driver.find_or_initialize_by(phone: Driver.normalize_value_for(:phone, phone.(i)))
      driver.assign_attributes(name: driver_name, status: :active)
      joined.(driver, 6.months.ago)
      driver.photo = SeedFiles.open("fleet", driver_photo) if driver_photo && driver.photo.blank?
      driver.save!
      default_driver.(vehicle, driver, Date.current - 180)
    end
  end

  # Spare drivers (accepted, not on a bus yet) and a scheduled change of default driver.
  spare = [ [ "Kumar s/o Rajan", "+65 9001 2233" ], [ "Lee Kok Wah", "+65 9002 3344" ],
            [ "Siti Nurhaliza", "+65 9003 4455" ], [ "Daniel Wong", "+65 9004 5566" ] ].map do |name, ph|
    Driver.find_or_initialize_by(phone: Driver.normalize_value_for(:phone, ph)).tap do |d|
      d.assign_attributes(name:, status: :active)
      joined.(d, 1.month.ago)
      d.save!
    end
  end
  Driver.find_or_create_by!(phone: "+6590055667") { |d| d.name = "Hafiz Rahman" }  # invite pending
  Driver.find_or_create_by!(phone: "+6590066778") { |d| d.assign_attributes(name: "Ong Boon Hock", status: :declined) }

  %w[PD3318K PD4472H PC8841T].zip(spare).each do |plate, driver|
    default_driver.(Vehicle.kept.find_by!(plate:), driver, Date.current - 60)
  end
  default_driver.(Vehicle.kept.find_by!(plate: "PD5126A"), spare.last, Date.current + 7)

  # notes: what the driver reads under the attendant in Point of Contact (Driver app)
  [ [ "Mdm Rosnah", "+65 9111 2233", "Travels on the bus. Call first if a child is not at the stop" ],
    [ "Mrs Lee Mei Ling", "+65 9111 3344", nil ], [ "Mr Chandran", "+65 9111 4455", nil ] ].each do |name, ph, notes|
    a = Attendant.kept.find_or_create_by!(name:) { it.phone = ph }
    a.update!(notes:) if notes && a.notes.blank?
  end
end
