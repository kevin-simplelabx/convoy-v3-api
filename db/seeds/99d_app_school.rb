# Convoy App School Bus (Phase 4) for the Tan Family of 99b_app_household.rb at St. Stephen's School (SimpleDrive):
# - St. Stephen's AY 2027 Bus Service Registration is scheduled (54_school_parents.rb saves it as a draft), so parents can
#   request the bus for 2027 and renew;
# - Ethan rides now: an Active app request for AY 2026, linked into the TAN Family at the school (Rachel and David as
#   guardians, by app id), on the first stop of the AM and PM Term 4 routes;
# - Lucas has an AY 2027 application sent through the app (ConvoyApp::Parents::Submit) with the registration fee unpaid;
# - Ethan's Change of Address was confirmed at a higher fare and waits for the parents to Agree (School page banner).
# Idempotent.
rachel = AppIdentity.find_by!(kind: "mobile", value: ConvoyApp.normalize("mobile", "+65 9188 2045")).app_account
household = rachel.household or raise "Run 99b_app_household.rb first"
member = household.members.find_by!(app_account: rachel)
ethan = household.dependants.find_by!(name: "Ethan Tan")
lucas = household.dependants.find_by!(name: "Lucas Tan")

with_company("SD") do
  admin = User.find_by!(email: "ops@simpledrive.sg")
  school = School.find_by!(name: "St. Stephen's School")
  this = school.academic_years.find_by!(key: "2026")
  reg = school.academic_years.find_by!(key: "2027").registration
  reg.update!(status: "scheduled") if reg && !reg.scheduled?

  # Ethan rides: rider, app request (Active), the Family as the school's family, a seat on Term 4 AM and PM.
  unless FamilyRider.exists?(dependant_id: ethan.id)
    now = Time.current
    start = Date.current.beginning_of_month
    req = school.bus_requests.create!(
      academic_year: this, kind: "new", source: "app", status: "Accepted", submitted_at: now - 60.days, household:, dependant: ethan, app_account: rachel,
      child_name: ethan.name, birth_date: ethan.birth_date, level: "P4", student_no: ethan.student_id, am: true, pm: true, address: household.address,
      postal: household.postal, lat: household.lat, lng: household.lng, start_when: "first", start_on: start, estimate: 420, quote_amount: 420,
      quote_base: 420, quote_unit: "month", quoted_at: now - 50.days, quoted_by: admin, offer_by: now - 48.days, terms_agreed_at: now - 60.days,
      **ConvoyApp::Parents.parent(rachel)
    )
    req.log!("Sent from the Convoy App by #{rachel.display_name}", by: "Parent", at: now - 60.days)
    BusRequests::Link.call(req, user: admin)
    req.update!(status: "Active")
    req.log!("First invoice paid. Service is active", by: admin, at: now - 49.days)
    rider = req.reload.school_rider
    rider.update!(starts_on: start, grade: "P4", lat: household.lat, lng: household.lng)
    %w[am pm].each do |session|
      plan = school.plans.where(session:, in_use: true).order(:effective_from).last or next
      route = plan.routes.order(:number).first or next
      stop = route.stops.order(:position).first or next
      SchoolRouteRider.find_or_create_by!(school_route: route, stop:, rid: rider.rid)
    end
  end

  # Lucas: an AY 2027 application from the app, registration fee not paid yet.
  unless BusRequest.exists?(dependant_id: lucas.id, kind: "new")
    ConvoyApp::Parents::Submit.call(member:, params: { school_id: school.id, agree: true,
                                                       children: [ { dependant_id: lucas.id, level: "P2", service: "both", start_when: "first" } ] })
  end

  # Ethan's move: confirmed at a higher fare, waiting for the parents to agree.
  unless BusRequest.exists?(dependant_id: ethan.id, kind: "adr")
    rider = SchoolRider.find_by!(dependant_id: ethan.id)
    kid = ConvoyApp::Parents::AddressChange.kids(household).find { it.dependant.id == ethan.id }
    rule = ConvoyApp::Parents::AddressChange.rule([ kid ], Date.current)
    move = ConvoyApp::Parents::AddressChange.dates(rule).first
    adr = school.bus_requests.create!(
      academic_year: this, kind: "adr", source: "app", status: "Requested", submitted_at: Time.current - 2.days, household:, dependant: ethan,
      app_account: rachel, school_rider: rider, family: Family.find_by(household_id: household.id, school:), child_name: ethan.name, level: rider.grade,
      old_address: rider.address, old_postal: rider.postal, address: "Blk 216 Bedok North St 1, #05-22", postal: "460216", lat: 1.3305, lng: 103.9381,
      am: true, pm: true, effective_on: move, current_fare: 420, estimate: 450,
      new_home: { "block" => "216", "street" => "Bedok North St 1", "floor" => "05", "unit" => "22", "line2" => nil, "postal" => "460216",
                  "lat" => 1.3305, "lng" => 103.9381 },
      **ConvoyApp::Parents.parent(rachel)
    )
    adr.log!("Change of address sent from the Convoy App by #{rachel.display_name}", by: "Parent", at: Time.current - 2.days)
    BusRequests::ConfirmChange.call(adr, amount: 460, note: "The new stop is on a longer route", user: admin, stop: "Blk 216 Bedok North St 1")
  end

  puts "Convoy App School Bus: Ethan riding (#{SchoolRider.find_by(dependant_id: ethan.id)&.rid}), " \
       "#{BusRequest.where(household_id: household.id).count} requests from the Tan Family"
end
