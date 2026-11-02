# Trip History: past runs marked completed (the 5-minute job does this in production), a run cancelled at the client's
# request and one by us, notes on runs worth a second look, drivers' reports with photos (the driver app sends
# these later) and a corrected record. Keyed by the note text / report / correction, so it runs once.
with_company("SD") do
  Time.use_zone(ActsAsTenant.current_tenant.timezone) do
    Occurrences::Complete.call
    ops = User.find_by!(email: "ops@simpledrive.sg")
    past = TripOccurrence.where(date: (Date.current - 30)..Date.yesterday).where.not(trip_id: nil)
    shuttle = Trip.kept.find_by!(label: "seed-mbc-shuttle")
    runs = past.where(trip: shuttle).completed.order(:date, :start_time).to_a

    if runs.size >= 4 && !past.exists?(cancelled_by_client: true)
      Occurrences::Edit.new(runs[-1], ops).cancel!(by_client: true)
      Occurrences::Edit.new(runs[-2], ops).cancel!
    end

    noted = runs.first
    if noted && OccurrenceNote.none?
      noted.history_notes.create!(author: ops, body: "Speed above 80 km/h recorded along the AYE. Driver spoken to and reminded of the 60 km/h limit on the route")
    end

    fixed = runs[1]
    if fixed && OccurrenceCorrection.none?
      TripHistory::Correct.call(occ: fixed, user: ops, params: {
        stops: [ { position: 0, arrived_at: Clock.hm(fixed.start_time + 4), departed_at: Clock.hm(fixed.start_time + 7), boarded: 11 } ],
        reason: "Driver app lost signal, times taken from the driver's log sheet"
      })
    end

    photo = Rails.root.join("db/seeds/files/fleet").glob("*.{png,jpg,jpeg}").first
    past.completed.where.not(vehicle_id: nil).order(date: :desc).limit(6).each_with_index do |occ, i|
      next if OccurrenceDriverReport.exists?(occurrence_id: occ.id, occurrence_date: occ.date)

      report = OccurrenceDriverReport.create!(occurrence: occ, driver_name: TripHistory.driver_name(occ), submitted_at: occ.ends_at + 10.minutes,
                                              note: [ "Smooth run, light traffic", "Heavy traffic on the PIE after an accident. Arrived 8 min late at stop 2",
                                                      "No issues" ][i % 3])
      report.photos.create!(image: File.open(photo), caption: "Drop-off") if photo && i.zero?
    end
  end
end
