# Stop Library sample for St. Stephen's School: one library stop per AM route stop of the seed (a PUDO point for
# pick-up and drop-off by the riders' homes), the school's catchment = its riders' postal codes; one stop kept for the
# school and waiting for the library; a photo request with two photos sent from the app, and a closed one with the photos
# the office received (Add Received Photos).
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  next if school.school_stops.exists?

  stops = SchoolRoute.joins(:plan).where(school_plans: { school_id: school.id, session: "am" }).flat_map { it.stops.to_a }
  first = nil
  stops.each_with_index do |rs, s|
    postal = format("46%04d", 100 + (s * 37))
    lat = 1.32 + (s * 0.004)
    lng = 103.92 + (s * 0.003)
    stop = Stops::Save.call({ name: rs.name, points: [
      { usage: "both", sizes: %w[S M L], primary: true, lat: lat + 0.0004, lng: lng + 0.0003, description: "Bus bay beside #{rs.name}",
        street_view_url: "https://www.google.com/maps/@#{lat},#{lng},3a,75y" },
      { usage: "pickup", sizes: %w[S M], lat: lat - 0.0003, lng: lng - 0.0002, description: "Side gate, small buses only" }
    ] }, user: admin)
    SchoolStop.create!(school:, stop:, postal_codes: [ postal ])
    first ||= stop
  end

  own = Stops::Save.call({ name: "SSS Gate B", points: [ { usage: "both", sizes: %w[S M L], primary: true, lat: 1.3141, lng: 103.9286 } ] },
                         user: admin, school:, in_library: false)
  Stops::Library.ask(own, User.find_by!(email: "dispatch@simpledrive.sg"))

  point = first.points.first
  req = StopPhotos.ask(point, audience: "both", user: admin, max: 4)
  [ [ "Mrs Tan Mei Ling", "parent" ], [ "Kumar s/o Rajan", "driver" ] ].each_with_index do |(name, role), i|
    req.submissions.create!(submitted_by_name: name, role:, submitted_at: Time.current - (i + 1).days, photo: SeedFiles.open("fleet", "bus-#{i + 1}.png"))
  end
end

with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  point = StopPoint.where(stop: school.school_stops.select(:stop_id), retired_at: nil).order(:id).second
  next if point.nil? || point.photo_requests.exists?

  req = StopPhotos.ask(point, audience: "driver", user: admin, max: 2)
  photos = [ 3, 4 ].map { |n| SeedFiles.open("fleet", "bus-#{n}.png") }
  StopPhotos.receive(req, photos:, by: "Kumar s/o Rajan", role: "driver", user: admin, street_view_url: "https://maps.app.goo.gl/sss-gate")
end
