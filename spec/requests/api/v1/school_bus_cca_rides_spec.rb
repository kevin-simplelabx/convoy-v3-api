require "rails_helper"

# School Bus › CCA Rides: settings (checks, price from Bus Fares), rides paid in the Convoy App for next week (cut-off,
# late adds while seats last), Bus Not Running giving credit, the credit used at the next payment, and no-school days.
RSpec.describe "School Bus CCA rides" do
  let(:company) { create(:company) }
  let(:user) { create(:user, company:, permissions: %w[plans]) }
  let!(:f) do
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School")
      year = AcademicYears::Create.call(school:, start_year: 2026, start_month: 1)
      year.terms.first.update!(starts_on: "2026-01-02", ends_on: "2026-05-29")
      year.terms.second.update!(starts_on: "2026-06-29", ends_on: "2026-11-20")
      year.holidays.create!(name: "Sports Day (no school)", starts_on: "2026-11-19", ends_on: "2026-11-19")
      tan = school.families.create!(code: "FAM-0001", name: "TAN Family", name_mode: "custom")
      lim = school.families.create!(code: "FAM-0002", name: "LIM Family", name_mode: "custom")
      { school:, tan:, lim: }
    end
  end
  let(:path) { api_v1_school_cca_rides_path(f[:school]) }

  before do
    travel_to Time.zone.local(2026, 11, 4, 9, 0) # Wednesday
    sign_in_as(user)
  end

  def pay(family, picks, today = Date.current) = within_tenant(company) { CcaRides::Pay.call(family, picks:, today:) }
  def pick(child, date) = { child_name: child, class_name: "P4 Faith", date: Date.parse(date) }

  it "saves settings, shows the week's rides, gives credit when the bus does not run and uses it next time" do
    put path, params: { enabled: true, price: 0, days: [ 2, 4 ], seats: 2 }, as: :json
    expect(json.dig(:error, :message)).to eq("Enter the price per ride")
    put path, params: { enabled: true, price: 8, days: [ 2, 4 ], seats: 2 }, as: :json
    expect(json.dig(:data, :setting)).to include(enabled: true, price: "8.0", days: [ 2, 4 ], seats: 2, saved_by: user.name)

    expect { pay(f[:tan], [ pick("Ethan Tan", "2026-11-17") ]) }.to raise_error(ApplicationService::Error, "Only next week can be booked")
    expect { pay(f[:tan], [ pick("Ethan Tan", "2026-11-11") ]) }.to raise_error(ApplicationService::Error, "The CCA bus does not run on Wednesdays")
    bill = pay(f[:tan], [ pick("Ethan Tan", "2026-11-10"), pick("Ethan Tan", "2026-11-12"), pick("Lucas Tan", "2026-11-12") ])
    expect(bill).to have_attributes(kind: "cca", total: 24, period_label: "CCA Bus · Week of Mon 9 Nov")
    expect(bill.lines.map(&:description)).to eq([ "CCA Bus · 2 rides × S$8.00 · Tue 10 Nov, Thu 12 Nov", "CCA Bus · 1 ride × S$8.00 · Thu 12 Nov" ])
    # After the Saturday cut-off: late adds only while seats are left
    late = Date.new(2026, 11, 8)
    expect { pay(f[:lim], [ pick("Amelia Lim", "2026-11-12") ], late) }.to raise_error(ApplicationService::Error, "The CCA bus on Thu 12 Nov is full")
    expect(pay(f[:lim], [ pick("Amelia Lim", "2026-11-10") ], late)).to have_attributes(period_label: "CCA Bus · Added Tue 10 Nov")

    get path
    d = json[:data]
    expect(d[:week_of]).to eq("2026-11-09")
    expect(d[:days].map { [ it[:label], it[:taken], it[:status] ] }).to eq([ [ "Tue 10 Nov", 2, "Open until Sat 7 Nov, 23:59" ], [ "Thu 12 Nov", 2, "Open until Sat 7 Nov, 23:59" ] ])
    expect(d[:kpis]).to eq(rides: 4, collected: "32.0", late: 1, not_riding: 0, credit_given: "0.0")
    expect(d[:days].flat_map { it[:rows] }.map { it[:bill_number] }).to all(be_present)

    post not_running_api_v1_school_cca_rides_path(f[:school]), params: { date: "2026-11-12", reason: "weather", note: "Lightning risk" }, as: :json
    expect(json.dig(:meta, :credited)).to eq(2)
    expect(json[:data][:days].last).to include(status: "Bus Not Running", off: hash_including(reason: "Bad weather: Lightning risk", credit: "16.0"))
    expect(json.dig(:data, :kpis, :credit_given)).to eq("16.0")
    post not_running_api_v1_school_cca_rides_path(f[:school]), params: { date: "2026-11-12", reason: "weather" }, as: :json
    expect(json.dig(:error, :message)).to eq("The CCA bus is already marked as not running on Thu 12 Nov")

    # The Tan family's S$16 credit pays the next week's two rides; Sports Day has no school
    next_bill = pay(f[:tan], [ pick("Ethan Tan", "2026-11-17"), pick("Ethan Tan", "2026-11-19") ], Date.new(2026, 11, 12))
    expect(next_bill).to have_attributes(gross: 16, credit_used: 16, total: 0, payments: [])
    expect(within_tenant(company) { CcaBooking.where(school_bill: next_bill).pluck(:method).uniq }).to eq([ "Credit" ])
    get path, params: { week_of: "2026-11-18" }
    expect(json.dig(:data, :days).last).to include(status: "No School", no_school: { run: false, kind: "school_holiday", label: "Sports Day (no school)", sub: "School holiday" }, can_no_school_credit: true)
    post not_running_api_v1_school_cca_rides_path(f[:school]), params: { date: "2026-11-19", reason: "no_school", note: "Sports Day" }, as: :json
    expect(json[:data][:days].last[:off]).to include(reason: "No school: Sports Day", credit: "8.0")

    # Saving the settings answers the week being viewed; an empty week has decimal figures
    put path, params: { enabled: true, price: 8, days: [ 2, 4 ], seats: 3, week_of: "2026-12-09" }, as: :json
    expect(json[:data]).to include(week_of: "2026-12-07")
    expect(json.dig(:data, :kpis)).to eq(rides: 0, collected: "0.0", late: 0, not_riding: 0, credit_given: "0.0")
  end
end
