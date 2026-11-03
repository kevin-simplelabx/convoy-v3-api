# School Bus parents sample for St. Stephen's School: the AY 2027 Bus Service Registration saved as a draft (Convoy OS
# defaults; siblings accepted when a seat is free), and Bus Service Requests — AY 2027 renewals from current riders and
# new families (some waitlisted), and AY 2026 mid-year requests (one to acknowledge, one acknowledged with a moved date);
# accepted with first invoices: one renewal paid (Active), one new family waiting to pay, one renewal lapsed; changes
# from current riders: a change of address, one waiting for the parent to agree a higher fare, a change of service and a stop;
# CCA Rides at S$8 a ride on Tuesdays and Thursdays: last week's rides (Thursday not run, so credit) and next week's;
# today's 08:00 email of requests waiting, recorded for the School Bus admins.
with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  year = school.academic_years.find_by!(key: "2027")
  this = school.academic_years.find_by!(key: "2026")

  unless year.registration
    SchoolRegistrations::Save.call(year, { auto_siblings: true, asks: %w[cls med emerg cca] }, user: admin)
  end

  unless school.bus_requests.exists?
    now = Time.current
    levels = school.levels.map(&:name)
    add = lambda do |at, o|
      req = school.bus_requests.create!({ source: "sample", submitted_at: at, start_on: SchoolRegistrations.first_day(o[:academic_year]) }.merge(o))
      req.log!(req.renew ? "Renewal requested in the Convoy App" : "Requested in the Convoy App", by: "Parent", at:)
      req
    end
    riders = SchoolRider.of_school_on(school, Date.current).where.not(grade: "P6").order(:rid).limit(12).to_a
    riders.each_with_index do |r, i|
      req = add.(now - (20 - i).days, academic_year: year, school_rider: r, renew: true, same: i.even?, tags: %w[Renewing], child_name: r.name,
                                      level: levels[levels.index(r.grade).to_i + 1], parent_name: r.parent_name, parent_phone: r.parent_contact,
                                      address: r.address, postal: r.postal, lat: r.lat, lng: r.lng, am: r.am, pm: r.pm)
      next unless i < 3

      req.update!(status: "Under Review")
      req.log!("Opened by #{admin.name}. Under review", by: admin, at: now - (10 - i).days)
    end
    near = riders.first
    [ [ "Chua Hui Min", "Chua Wei Liang", "+65 9182 3301", "P1", 0.002, nil ], [ "Ng Jun Jie", "Ng Mei Ling", "+65 8123 4410", "P3", -0.003, nil ],
      [ "Pillai Aarav", "Pillai Priya", "+65 9765 1022", "P2", 0.06, "New area" ], [ "Rahman Haziq", "Rahman Aisyah", "+65 8890 2213", "P4", 0.001, "Route full" ] ]
      .each_with_index do |(child, parent, phone, level, off, reason), i|
        req = add.(now - (6 - i).days, academic_year: year, child_name: child, parent_name: parent, parent_phone: phone, level:,
                                       parent_email: "#{parent.downcase.tr(' ', '.')}@example.com", address: near.address, postal: near.postal,
                                       lat: near.lat + off, lng: near.lng + off, pm: i != 1)
        next unless reason

        req.update!(status: "Waitlisted", reason:)
        req.log!("Waitlisted. #{reason}", by: admin, at: now - 1.day)
      end

    days = BusRequests::Days.new
    mid = { academic_year: this, start_when: "asap", address: near.address, postal: near.postal, lat: near.lat, lng: near.lng }
    add.(now - 1.day, mid.merge(child_name: "Teo Jia En", parent_name: "Teo Rachel", parent_phone: "+65 9001 7788", level: "P2"))
    acked = add.(now - 9.days, mid.merge(child_name: "Koh Isaac", parent_name: "Koh Daniel", parent_phone: "+65 9334 5566", level: "P4",
                                         start_when: "fixed", start_on: days.next_working(Date.current + 21), fix_why: "move"))
    answer = days.next_working(Date.current + 7)
    acked.update!(status: "Under Review", acked_at: now - 7.days, acked_by: admin, answer_by: answer + 7, ack_note: "We are checking Bus 2", ack_plan_weeks: 3)
    acked.log!("Acknowledged. Answer expected by #{answer.strftime('%d/%m/%Y')}. Note to the parent: We are checking Bus 2", by: admin, at: now - 7.days)
    acked.answer_moves.create!(from_date: answer, to_date: answer + 7, reason: "Waiting for a bigger bus", moved_at: now - 2.days, moved_by: admin)
    acked.log!("Answer date moved to #{(answer + 7).strftime('%d/%m/%Y')}. Reason: Waiting for a bigger bus", by: admin, at: now - 2.days)
  end

  unless SchoolBill.where(school:).exists?
    reqs = school.bus_requests.where(academic_year: year).order(:submitted_at).to_a
    paid, lapsed = reqs.select(&:renew).first(2)
    fresh = reqs.find { it.child_name == "Chua Hui Min" }
    BusRequests::Accept.call([ paid, lapsed, fresh ], user: admin)
    BusRequests::RecordPayment.call(paid.reload, method: "PayNow", user: admin)
    lapsed.update!(offer_by: 2.hours.ago)
    lapsed.first_bill.update!(due_at: lapsed.offer_by, due_on: lapsed.offer_by.to_date)
  end

  unless school.bus_requests.where.not(kind: "new").exists?
    riders = SchoolRider.of_school_on(school, Date.current).where.not(lat: nil).order(:rid).offset(20).limit(4).to_a
    now = Time.current
    days = BusRequests::Days.new
    mk = lambda do |r, at, o|
      req = school.bus_requests.create!({ source: "sample", submitted_at: at, school_rider: r, child_name: r.name, level: r.grade, parent_name: r.parent_name,
                                          parent_phone: r.parent_contact, am: r.am, pm: r.pm, current_fare: 420 }.merge(o))
      req.log!({ "adr" => "Change of address requested in the Convoy App", "svc" => "Change of service requested in the Convoy App",
                 "stop" => "Stop of the bus service requested in the Convoy App" }[req.kind], by: "Parent", at:)
      req
    end
    a, b, c, d = riders
    move = days.next_working(Date.current + 14)
    mk.(a, now - 2.days, kind: "adr", effective_on: move, old_address: a.address, address: "Blk 216 Bedok North Street 1", postal: "460216",
                         lat: a.lat + 0.004, lng: a.lng + 0.004)
    up = mk.(b, now - 4.days, kind: "adr", effective_on: move + 7, old_address: b.address, address: "Blk 9 Changi Village Road", postal: "500009",
                              lat: b.lat + 0.03, lng: b.lng + 0.03)
    up.update!(status: "Accepted", agree: "wait", new_stop: "Blk 9 Changi Village Road", quote_amount: 480, quote_unit: "month", quoted_at: now - 1.day,
               quoted_by: admin)
    up.log!("New pick-up Blk 9 Changi Village Road, S$480.00 a month from #{(move + 7).strftime('%d/%m/%Y')}. Waiting for the parent to agree", by: admin,
                                                                                                                                              at: now - 1.day)
    mk.(c, now - 1.day, kind: "svc", effective_on: days.next_working(Date.current + 7), old_am: true, old_pm: true, old_cca: false, am: true, pm: false,
                        estimate: 260)
    last = (Date.current + 30).end_of_month
    mk.(d, now - 3.days, kind: "stop", last_on: last, stop_why: "move", notice_n: 1, notice_unit: "months", earliest_on: last, early: false)
  end

  unless school.cca_bookings.exists?
    CcaRides::SaveSettings.call(school, { enabled: true, price: 8, days: [ 2, 4 ], seats: 40 }, user: admin)
    kids = SchoolRider.of_school_on(school, Date.current).order(:rid).limit(10).to_a
    families = kids.each_slice(2).map do |pair|
      last = pair.first.name.split.first
      fam = school.families.create!(code: Family.next_code, name: "#{last.upcase} Family", name_mode: "custom", sample: true)
      Families.link(fam, school, pair.map(&:rid))
      [ fam, pair ]
    end
    last_week = CcaRides.monday(Date.current) - 7
    families.each do |fam, pair|
      picks = pair.flat_map { |k| [ 1, 3 ].map { { child_name: k.name, class_name: k.grade, school_rider: k, date: last_week + it } } }
      CcaRides::Pay.call(fam, picks:, today: last_week - 3)
    end
    CcaRides::NotRunning.call(school, date: last_week + 3, reason: "weather", note: "Lightning risk", user: admin)
    following = CcaRides.monday(Date.current) + 7
    families.first(3).each do |fam, pair|
      CcaRides::Pay.call(fam, picks: [ { child_name: pair.first.name, class_name: pair.first.grade, school_rider: pair.first, date: following + 1 } ])
    end
  end

  BusRequests::Digest.new(school.company).call
end
