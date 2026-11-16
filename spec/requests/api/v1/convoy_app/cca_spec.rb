require "rails_helper"

# Convoy App › CCA Bus per ride (Phase 5): next week and the Saturday 23:59 cut-off in the company's time, Add Ride / Booked /
# Not Riding / Full states, Same Days Every Week, pay to confirm (credit first, then PayNow or card, never Bank Transfer),
# late adds while seats last, Not Riding freeing the seat, and who may pay (the Billing Contact).
RSpec.describe "Convoy App CCA bus" do
  # Wednesday: next week is Mon 18 Jan, the cut-off Sat 16 Jan 23:59 (before the accounts sign in, so their tokens are valid)
  before { travel_to Time.zone.local(2027, 1, 13, 9, 0) }

  let(:company) { create(:company, name: "SimpleDrive") }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School", short_name: "SSS")
      year = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      year.terms.first.update!(starts_on: "2027-01-04", ends_on: "2027-05-28")
      CcaRideSetting.create!(school:, enabled: true, price: 8, days: [ 2, 4 ], seats: 2)
      SchoolPaymentMethod.create!(school:, bank_on: true, paynow_on: true, card_on: true, card_fee_kind: "pct", card_fee: 2)
      { school:, year: }
    end
  end
  let!(:rachel) { app_user(mobile: "9188 2045", name: %w[Rachel Tan]) }
  let!(:david) { app_user(mobile: "9177 3301", name: %w[David Tan]) }
  let!(:home) do
    h = Household.create!(name: "Tan Family", postal: "460412", block: "412", street: "Bedok North Ave 2", floor: "08", unit: "123", created_by: rachel[0])
    h.members.create!(app_account: rachel[0], status: :active, admin: true, billing_contact: true, relationship: "Mother", invited_via: :creator, joined_at: 1.day.ago)
    h.members.create!(app_account: david[0], status: :active, relationship: "Father", invited_via: :manual, joined_at: 1.day.ago)
    h
  end
  let!(:ethan) { home.dependants.create!(name: "Ethan Tan", birth_date: "2017-03-14", level: "P4", school_id: f[:school].id, school_name: "St. Stephen's School") }
  let!(:lucas) { home.dependants.create!(name: "Lucas Tan", birth_date: "2020-08-02", level: "P1", school_id: f[:school].id, school_name: "St. Stephen's School") }
  let!(:tan) do
    within_tenant(company) do
      fam = f[:school].families.create!(code: "FAM-0001", name: "TAN Family", name_mode: "custom", household_id: home.id)
      [ [ "R1", ethan ], [ "R2", lucas ] ].each do |rid, dep|
        f[:school].riders.create!(rid:, name: dep.name, grade: dep.level, postal: "460412", source: "manual", dependant_id: dep.id)
        FamilyRider.create!(family: fam, school: f[:school], rid:, dependant_id: dep.id)
      end
      fam
    end
  end
  let!(:lim) do
    within_tenant(company) do
      fam = f[:school].families.create!(code: "FAM-0002", name: "LIM Family", name_mode: "custom")
      %w[Amelia Ben].each { f[:school].riders.create!(rid: "L-#{it}", name: "#{it} Lim", grade: "P3", postal: "460101", source: "manual") }
      fam
    end
  end

  def token = @token || rachel[1]

  def api(verb, path, token: self.token, **params)
    return get(path, params:, headers: app_as(token)) if verb == :get

    public_send(verb, path, params:, headers: app_as(token), as: :json)
  end

  def later(time)
    travel_to time
    @token = app_token(mobile: "9188 2045")
    @david = app_token(mobile: "9177 3301")
  end

  def tenant(&) = within_tenant(company, &)
  def pick(dep, date) = { dependant_id: dep.id, date: }
  def book_lim(*dates)
    tenant do
      dates.each_with_index do |d, i|
        f[:school].cca_bookings.create!(family: lim, child_name: %w[Amelia Ben][i % 2] + " Lim", date: d, price: 8, paid_on: "2027-01-10", method: "PayNow")
      end
    end
  end

  def week(**params)
    api(:get, api_v1_convoy_app_cca_path, **params)
    json[:data]
  end

  it "shows next week with the cut-off, each child's days and the ways to pay without Bank Transfer" do
    d = week
    expect(d[:schools].sole).to include(name: "St. Stephen's School")
    expect(d).to include(price: "8.0", days: [ 2, 4 ], days_text: "Tue and Thu", week_of: "2027-01-18", week_text: "Week of Mon 18 Jan", can_pay: true, credit: nil)
    expect(d[:rule]).to eq("Tue and Thu. Book next week by Saturday 23:59 and pay to confirm. After that, a ride can be added if the bus has a seat.")
    expect(d[:deadline]).to include(open: true, text: "Book and pay by Sat 16 Jan, 23:59 · closes in 3 days", urgent: false)
    expect(Time.zone.parse(d[:deadline][:closes_at])).to eq(Time.zone.local(2027, 1, 16, 23, 59, 59))
    expect(d[:methods].pluck(:key)).to eq(%w[paynow card])
    expect(d[:kids].pluck(:name)).to eq([ "Ethan Tan", "Lucas Tan" ])
    day = d[:kids].first[:days].first
    expect(day).to include(date: "2027-01-19", label: "Tue 19 Jan", phase: "open", can_pick: true, sub: "S$8.00", booking: nil)
    expect(d[:kids].first[:same_days]).to include(shown: true, on: false, text: "Pick the same days for Ethan each week")

    d = week(tab: "this")
    expect(d).to include(week_of: "2027-01-11", deadline: hash_including(open: false, text: "Closed for changes. A ride can still be added if the bus has a seat."))
    expect(d[:kids].first[:same_days][:shown]).to be(false)
    expect(d[:kids].first[:days].map { [ it[:label], it[:phase], it[:tag] ] }).to eq([ [ "Tue 12 Jan", "past", "Not Booked" ], [ "Thu 14 Jan", "late", nil ] ])
    expect(d[:kids].first[:days].last).to include(can_pick: true, sub: "After the cut-off · 2 seats left · paid at once")

    api(:get, api_v1_convoy_app_school_path)
    expect(json.dig(:data, :cca)).to include(title: "CCA Bus · Next Week", booked: false, sub: "Book and pay by Sat 16 Jan, 23:59 · S$8.00 a ride")
  end

  it "quotes and pays: credit first, then PayNow or card, never Bank Transfer, one CCA bill per payment" do
    api(:post, api_v1_convoy_app_cca_quote_path, school_id: f[:school].id, method: "card", picks: [ pick(ethan, "2027-01-19"), pick(ethan, "2027-01-21"), pick(lucas, "2027-01-19") ])
    expect(json[:data]).to include(rides: 3, gross: "24.0", credit: "0.0", subtotal: "24.0", admin_fee: "0.48", total: "24.48", method: "card", book_with_credit: false)
    expect(json[:data][:rows]).to eq([ { k: "3 rides × S$8.00", v: "24.0" }, { k: "Card admin fee", v: "0.48" } ])
    expect(tenant { SchoolBill.count + CcaBooking.count }).to eq(0)

    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "bank", picks: [ pick(ethan, "2027-01-19") ])
    expect(json.dig(:error, :message)).to eq("Pick how to pay: PayNow or card")
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "card", picks: [ pick(ethan, "2027-01-19"), pick(ethan, "2027-01-21"), pick(lucas, "2027-01-19") ])
    expect(response).to have_http_status(:created), json.inspect
    expect(json[:data]).to include(rides: 3, paid: "24.48", admin_fee: "0.48", method: "Card")
    expect(json[:data][:invoice]).to include(period: "CCA Bus · Week of Mon 18 Jan", total: "24.0")
    ethan_days = json.dig(:data, :week, :kids).first[:days]
    expect(ethan_days.map { [ it[:tag], it[:sub] ] }).to eq([ [ "Booked", "Paid 13 Jan 2027 · Card" ], [ "Booked", "Paid 13 Jan 2027 · Card" ] ])
    tenant do
      bill = SchoolBill.sole
      expect(bill).to have_attributes(kind: "cca", family_id: tan.id, total: 24, credit_used: 0, week_of: Date.new(2027, 1, 18))
      expect(bill.payments.sole).to have_attributes(source: "app", method: "Card", amount: 24, admin_fee: 0.48)
      expect(CcaBooking.where(school_bill: bill).pluck(:method).uniq).to eq([ "Card" ])
    end

    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-19") ])
    expect(json.dig(:error, :message)).to eq("Ethan Tan is already booked on Tue 19 Jan")
    api(:get, api_v1_convoy_app_school_path)
    expect(json.dig(:data, :cca)).to include(booked: true, sub: "Booked: Ethan Tue, Lucas Tue, Ethan Thu")

    # Credit pays first; credit that covers everything books with no payment
    tenant { CcaCredit.create!(school: f[:school], family: tan, child_name: "Ethan Tan", date: "2027-01-07", amount: 8, reason: "Bus problem") }
    expect(week[:credit]).to eq(amount: "8.0", text: "S$8.00 credit", sub: "From rides the bus did not run. Used first when you pay.")
    api(:post, api_v1_convoy_app_cca_quote_path, school_id: f[:school].id, method: "paynow", picks: [ pick(lucas, "2027-01-21") ])
    expect(json[:data]).to include(gross: "8.0", credit: "8.0", total: "0.0", admin_fee: "0.0", book_with_credit: true, method: nil)
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, picks: [ pick(lucas, "2027-01-21") ])
    expect(json[:data]).to include(paid: "0.0", method: "Credit")
    expect(json.dig(:data, :week, :credit)).to be_nil
    tenant { expect(SchoolBill.order(:id).last).to have_attributes(total: 0, credit_used: 8, payments: []) }
  end

  it "closes next week at Saturday 23:59 in the company's time: after it only a seat left can be added" do
    book_lim("2027-01-19", "2027-01-19")
    later(Time.zone.local(2027, 1, 16, 23, 59))
    d = week
    expect(d[:deadline]).to include(open: true, urgent: true, text: "Book and pay by Sat 16 Jan, 23:59 · closes tonight")
    expect(d[:kids].first[:days].first).to include(phase: "open", can_pick: true, tag: nil) # the cut-off is not past, so full seats do not matter yet

    later(Time.zone.local(2027, 1, 17, 0, 0))
    d = week
    expect(d[:deadline]).to include(open: false)
    full, free = d[:kids].first[:days]
    expect(full).to include(phase: "late", can_pick: false, tag: "Full", sub: "No seats left on the CCA bus", seats_left: 0)
    expect(free).to include(phase: "late", can_pick: true, sub: "After the cut-off · 2 seats left · paid at once")
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-19") ])
    expect(json.dig(:error, :message)).to eq("The CCA bus on Tue 19 Jan is full")
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-21") ])
    expect(response).to have_http_status(:created)
    tenant do
      expect(SchoolBill.sole.period_label).to eq("CCA Bus · Added Thu 21 Jan")
      expect(CcaBooking.find_by!(family: tan)).to have_attributes(late: true, method: "PayNow")
    end
    expect(week[:kids].first[:days].last).to include(tag: "Booked", sub: "Paid 17 Jan 2027 · PayNow · added after the cut-off")

    # Today and the days before can no longer be booked, nor a week further on, nor a day the bus does not run
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-26") ])
    expect(json.dig(:error, :message)).to eq("Only next week can be booked")
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-20") ])
    expect(json.dig(:error, :message)).to eq("The CCA bus does not run on Wednesdays")
  end

  it "lets any adult say Not Riding, frees the seat, and keeps Riding After All to a free seat" do
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-19") ])
    booking = tenant { CcaBooking.sole }
    book_lim("2027-01-19")
    expect(week[:kids].first[:days].first).to include(can_not_riding: true, not_riding_label: "Not Riding", seats_left: 0)

    @david = app_token(mobile: "9177 3301")
    api(:patch, api_v1_convoy_app_cca_booking_not_riding_path(booking), token: @david, not_riding: true)
    expect(json[:data]).to include(id: booking.id, not_riding: true)
    day = week[:kids].first[:days].first
    expect(day).to include(tag: "Not Riding", tone: "neutral", sub: "Charged · the bus will not wait", not_riding_label: "Riding After All", seats_left: 1)

    # Another family takes the freed seat: Riding After All then needs a seat
    tenant { f[:school].cca_bookings.create!(family: lim, child_name: "Ben Lim", date: "2027-01-19", price: 8, paid_on: "2027-01-12", method: "PayNow", late: true) }
    api(:patch, api_v1_convoy_app_cca_booking_not_riding_path(booking), not_riding: false)
    expect(json.dig(:error, :message)).to eq("The CCA bus on Tue 19 Jan is full, so the seat cannot be taken back")

    # Another Family's booking is a 404; a ride that has gone cannot be changed
    other = tenant { CcaBooking.where(family: lim).first }
    api(:patch, api_v1_convoy_app_cca_booking_not_riding_path(other), not_riding: true)
    expect(response).to have_http_status(:not_found)
    later(Time.zone.local(2027, 1, 20, 9, 0))
    api(:patch, api_v1_convoy_app_cca_booking_not_riding_path(booking), not_riding: false)
    expect(json.dig(:error, :message)).to eq("A ride that has gone cannot be changed")
  end

  it "keeps Same Days Every Week to the school's CCA days and pre-picks next week with it" do
    api(:put, api_v1_convoy_app_cca_same_days_path, school_id: f[:school].id, dependant_id: ethan.id, days: [ 2, 3 ])
    expect(json.dig(:error, :message)).to eq("The CCA bus runs on Tue and Thu")
    api(:put, api_v1_convoy_app_cca_same_days_path, token: david[1], school_id: f[:school].id, dependant_id: ethan.id, days: [ 2, 4 ])
    expect(json[:data]).to eq(dependant_id: ethan.id, on: true, days: [ 2, 4 ], text: "Tue and Thu are picked for Ethan each week. Still pay by Saturday 23:59 to confirm")

    kid = week[:kids].first
    expect(kid[:same_days]).to include(on: true, days: [ 2, 4 ])
    expect(kid[:days].pluck(:picked_by_same_days)).to eq([ true, true ])
    expect(kid[:days].first[:sub]).to eq("S$8.00 · picked by Same Days Every Week")
    expect(week[:kids].last[:same_days][:on]).to be(false)
    expect(week(tab: "this")[:kids].first[:days].pluck(:picked_by_same_days)).to eq([ false, false ])

    api(:put, api_v1_convoy_app_cca_same_days_path, school_id: f[:school].id, dependant_id: ethan.id, days: [])
    expect(json[:data]).to include(on: false, days: [])
    expect(tenant { CcaStandingDay.count }).to eq(0)
  end

  it "checks the Billing Contact, the children and the school" do
    api(:post, api_v1_convoy_app_cca_payments_path, token: david[1], school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-19") ])
    expect(response).to have_http_status(:forbidden)
    expect(json[:error]).to include(code: "billing_only")
    expect(tenant { CcaBooking.count }).to eq(0)
    api(:post, api_v1_convoy_app_cca_quote_path, token: david[1], school_id: f[:school].id, method: "paynow", picks: [ pick(ethan, "2027-01-19") ])
    expect(response).to have_http_status(:ok)

    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [])
    expect(json.dig(:error, :message)).to eq("Pick at least one day")
    api(:post, api_v1_convoy_app_cca_payments_path, school_id: f[:school].id, method: "paynow", picks: [ { dependant_id: 0, date: "2027-01-19" } ])
    expect(json.dig(:error, :message)).to eq("Pick a child who rides this school's bus")
    api(:get, api_v1_convoy_app_cca_path, school_id: 0)
    expect(response).to have_http_status(:not_found)

    tenant { f[:school].cca_ride_setting.update!(enabled: false) }
    expect(week).to eq(schools: [])
    api(:get, api_v1_convoy_app_school_path)
    expect(json.dig(:data, :cca)).to be_nil
  end
end
