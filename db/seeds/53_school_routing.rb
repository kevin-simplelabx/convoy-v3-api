# Route Plans sample: the company's routing parameters (Balanced priority, High effort) and a feasibility study for a
# prospect school with students by postal code and bus prices (run it from the screen: the routing service plans it).
# The seeded St. Stephen's plans stay as they are (source "manual"); new plans come from Run Routing.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  RoutingSetting.find_or_create_by!(company: ActsAsTenant.current_tenant) do |s|
    s.params = { "preset" => "BALANCED", "effort" => "high", "hardCap" => 75, "targetCap" => 50 }
    s.updated_by = admin
  end

  next if FeasibilityStudy.exists?

  PostalGeocode.find_or_create_by!(country: "SG", postal: "449144") { |g| g.assign_attributes(found: true, lat: 1.3065, lng: 103.9142, address: "2 Mountbatten Road", looked_up_at: Time.current) }
  study = FeasibilityStudy.create!(name: "Mountbatten Primary bid", school_mode: "prospect", prospect_name: "Mountbatten Primary", prospect_postal: "449144",
                                   prospect_lat: 1.3065, prospect_lng: 103.9142, pickup: "lib", walk_m: 400, created_by: admin)
  study.rows.create!([ { postal: "460100", riders: 9 }, { postal: "460137", riders: 8 }, { postal: "460174", riders: 6, session: "AM" },
                       { postal: "460211", riders: 11 }, { postal: "460248", riders: 10, session: "PM", level: "P3" } ])
  study.bus_prices.create!([ { bus_type: "LARGE_45", monthly: 5200, attendant: 900 }, { bus_type: "MEDIUM_23", monthly: 3600, attendant: 450 },
                             { bus_type: "SMALL_13", monthly: 2400 } ])
  [ [ 3, 150, 100 ], [ 6, 180, 120 ], [ nil, 220, 150 ] ].each.with_index(1) { |(km, f, o), i| study.fare_tiers.create!(position: i, max_km: km, fare: f, one_way_fare: o) }
  study.scenarios.create!(position: 1, name: "Big buses", sizes: %w[LARGE_45 MEDIUM_23], attendant: "STATUTORY", margin_pct: 25)
  study.scenarios.create!(position: 2, name: "Small buses only", sizes: %w[MEDIUM_23 SMALL_13], attendant: "ALL_BUSES", margin_pct: 25,
                          extra_buses: { "AM" => { "SMALL_13" => 1 } })
end
