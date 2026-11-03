# School Bus Year Setup sample for St. Stephen's School: postal code, AY 2026 (4 terms, public holidays and the school's
# own holidays, a special day, calendar locked) and AY 2027 (terms set, not locked), and a rider list effective from the
# start of AY 2026 built from the seeded routes' stops (homes already placed, OneMap lookups cached).
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  school.update!(postal: "455789") if school.postal.nil?

  terms = {
    2026 => [ %w[2026-01-02 2026-03-13], %w[2026-03-23 2026-05-29], %w[2026-06-29 2026-09-04], %w[2026-09-14 2026-11-20] ],
    2027 => [ %w[2027-01-04 2027-03-12], %w[2027-03-22 2027-05-28], %w[2027-06-28 2027-09-03], %w[2027-09-13 2027-11-19] ]
  }
  terms.each do |y, list|
    next if school.academic_years.exists?(key: y.to_s)

    year = AcademicYears::Create.call(school:, start_year: y, start_month: 1)
    year.update!(structure: "term", period_count: 4)
    year.terms.delete_all
    list.each.with_index(1) { |(from, to), i| year.terms.create!(position: i, starts_on: from, ends_on: to) }
    PublicHoliday.between(year.starts_on, year.ends_on).each do |h|
      year.holidays.create!(name: h.name, starts_on: h.date, ends_on: h.date, public_holiday: h)
    end
    next unless y == 2026

    year.holidays.create!(name: "Teachers' Day (school holiday)", starts_on: "2026-09-04", ends_on: "2026-09-04")
    year.holidays.create!(name: "Children's Day (school holiday)", starts_on: "2026-10-09", ends_on: "2026-10-09")
    year.special_days.create!(date: "2026-11-13", kind: "early_dismissal", time: "11:30", description: "Prize Giving Day")
    SchoolSetup.lock!(school:, year:, section: :calendar, user: admin)
  end

  unless school.levels.exists?
    SchoolLevels::Save.call(school, %w[P1 P2 P3 P4 P5 P6].map { { name: it, section: "pri", final: it == "P6" } }, user: admin)
  end
  ay = school.academic_years.find_by!(key: "2026")
  unless ay.bus_sessions.exists?
    BusSessions::Save.call(ay, [
      { name: "AM Arrival", direction: "to_school", service: "d2d", max_journey_minutes: 60, days: [ 1, 2, 3, 4, 5 ], arrive_from: "07:00", arrive_to: "07:20" },
      { name: "PM Departure", direction: "to_home", service: "d2d", max_journey_minutes: 60, days: [ 1, 2, 3, 4, 5 ], dismissal: "13:30", depart: "13:40",
        arrive_from: "13:55", arrive_to: "14:40", variants: [ { days: [ 3 ], dismissal: "12:30", depart: "12:40", arrive_from: "12:55", arrive_to: "13:40" } ] },
      { name: "CCA Home", direction: "to_home", cca: true, service: "p2p", max_journey_minutes: 45, days: [ 2, 4 ], dismissal: "16:30", depart: "16:40",
        arrive_from: "16:50", arrive_to: "17:30" }
    ], user: admin)
  end
  unless school.attendant_policy
    school.create_attendant_policy!(needs: "statutory", provided_by: "operator")
    SchoolSetup.lock!(school:, section: :attendants, user: admin)
  end

  next if school.rider_datasets.exists?

  first = %w[Wei\ Ling Jun\ Hao Hui\ Min Kai\ Xuan Mei\ Ting Zhi\ Hao Yu\ Xin Jia\ Le Shu\ Hui Rui\ En Xin\ Yi Hao\ Ran]
  last = %w[Tan Lim Lee Ng Goh Chua Ong Wong Koh Teo]
  stops = SchoolRoute.joins(:plan).where(school_plans: { school_id: school.id, session: "am" }).flat_map { it.stops.to_a }
  rows = []
  stops.each_with_index do |stop, s|
    postal = format("46%04d", 100 + (s * 37))
    lat = 1.32 + (s * 0.004)
    lng = 103.92 + (s * 0.003)
    PostalGeocode.find_or_create_by!(country: "SG", postal:) { |g| g.assign_attributes(found: true, lat:, lng:, address: stop.name, looked_up_at: Time.current) }
    stop.riders_count.times do |k|
      n = rows.size
      rows << { rid: "S-#{1001 + n}", name: "#{last[n % last.size]} #{first[(n * 7) % first.size]}", gender: n.even? ? "F" : "M",
                grade: "P#{(n % 6) + 1}", address: "#{stop.name} ##{format('%02d', k + 2)}-#{100 + n}", postal:, lat:, lng:,
                am: true, pm: n % 9 != 0, cca_days: n % 5 == 0 ? [ 2, 4 ] : [], parent_name: "#{last[n % last.size]} Ah #{%w[Kow Huat Seng Beng][n % 4]}",
                parent_contact: format("9%07d", 1_234_000 + n) }
    end
  end
  csv = CSV.generate do |out|
    out << %w[student_id student_name gender grade_class address postal_code am pm cca_days parent_name parent_contact]
    rows.each { |r| out << [ r[:rid], r[:name], r[:gender], r[:grade], r[:address], r[:postal], r[:am] ? "Y" : "N", r[:pm] ? "Y" : "N", r[:cca_days].map { SchoolRider::DAYS[it - 1] }.join(";"), r[:parent_name], r[:parent_contact] ] }
  end
  Tempfile.create([ "SSS riders 2026", ".csv" ]) do |f|
    f.write(csv)
    f.rewind
    dataset = school.rider_datasets.create!(effective_from: "2026-01-02", file: f, file_name: "SSS riders 2026.csv", uploaded_by: admin,
                                            riders_count: rows.size, status: "ready")
    now = Time.current
    SchoolRider.insert_all!(rows.map { it.merge(company_id: school.company_id, school_id: school.id, rider_dataset_id: dataset.id, source: "csv", created_at: now, updated_at: now) })
  end
end
