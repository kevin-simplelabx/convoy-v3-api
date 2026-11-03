require "rails_helper"

# School Bus › Year Setup › Terms & Semesters: New Academic Year (copy days and structure), Save Calendar (rules, then
# locked), Unlock to Edit, school days per term, Delete Year (before it starts, Admins only).
RSpec.describe "School Bus academic years" do
  let(:company) { create(:company) }
  let!(:school) { within_tenant(company) { School.create!(name: "St. Stephen's School") } }
  let(:terms) do
    [ { starts_on: "2027-01-04", ends_on: "2027-03-12" }, { starts_on: "2027-03-22", ends_on: "2027-05-28" },
      { starts_on: "2027-06-28", ends_on: "2027-09-03" }, { starts_on: "2027-09-13", ends_on: "2027-11-19" } ]
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  it "creates a year, saves and locks its calendar, and unlocks it" do
    post api_v1_school_academic_years_path(school), params: { start_year: 2027, start_month: 1 }
    expect(response).to have_http_status(:created)
    year = json[:data]
    expect(year).to include(key: "2027", starts_on: "2027-01-01", ends_on: "2027-12-31", structure: "semester", period_count: 2,
                            operating_days: [ 1, 2, 3, 4, 5 ], calendar_locked: nil)
    expect(year[:terms].map { |t| t[:label] }).to eq([ "Semester 1", "Semester 2" ])

    put calendar_api_v1_academic_year_path(year[:id]), params: { structure: "term", period_count: 4, operating_days: [ 1, 2, 3, 4, 5 ],
                                                                terms: terms.values_at(1, 0, 2, 3) }
    expect(json.dig(:error, :message)).to eq("Term 2 must start after Term 1 ends")
    put calendar_api_v1_academic_year_path(year[:id]), params: { structure: "term", period_count: 3, operating_days: [], terms: }
    expect(json.dig(:error, :message)).to eq("Pick at least one operating day")
    put calendar_api_v1_academic_year_path(year[:id]), params: { structure: "term", period_count: 4, operating_days: [ 1, 2, 3, 4, 5 ],
                                                                terms: terms[0, 3] + [ { starts_on: "2027-09-13", ends_on: "2028-01-05" } ] }
    expect(json.dig(:error, :message)).to eq("Term 4 must be inside AY 2027 (1 Jan 2027 to 31 Dec 2027)")

    put calendar_api_v1_academic_year_path(year[:id]), params: { structure: "term", period_count: 4, operating_days: [ 1, 2, 3, 4, 5 ],
                                                                cca_same_as_terms: false,
                                                                terms: terms.map { |t| t.merge(cca_starts_on: t[:starts_on], cca_ends_on: "2028-01-05") } }
    expect(json.dig(:error, :message)).to eq("Term 1 CCA / ASA must be inside AY 2027 (1 Jan 2027 to 31 Dec 2027)")
    put calendar_api_v1_academic_year_path(year[:id]), params: { structure: "term", period_count: 4, operating_days: [ 1, 2, 3, 4, 5 ],
                                                                cca_same_as_terms: true, terms: }
    d = json[:data]
    expect(d[:calendar_locked]).to include(by: be_present)
    expect(d[:terms].map { |t| [ t[:label], t[:school_days] ] }).to eq([ [ "Term 1", 50 ], [ "Term 2", 50 ], [ "Term 3", 50 ], [ "Term 4", 50 ] ])
    expect(d[:school_days]).to eq(200)

    put calendar_api_v1_academic_year_path(year[:id]), params: { structure: "term", period_count: 4, operating_days: [ 1, 2, 3, 4, 5, 6 ], terms: }
    expect(json.dig(:error, :message)).to eq("Terms & Semesters is locked. Unlock to edit")
    post unlock_api_v1_academic_year_path(year[:id]), params: { section: "calendar" }
    expect(json.dig(:data, :calendar_locked)).to be_nil

    post api_v1_school_academic_years_path(school), params: { start_year: 2027, start_month: 6 }
    expect(json.dig(:error, :message)).to eq("This overlaps AY 2027")
    post api_v1_school_academic_years_path(school), params: { start_year: 2028, start_month: 1, copy_from_id: year[:id] }
    expect(json[:data]).to include(key: "2028", structure: "term", period_count: 4)
    expect(json.dig(:data, :terms).map { |t| t[:starts_on] }).to eq([ nil, nil, nil, nil ])

    get api_v1_school_academic_years_path(school)
    expect(json[:data].map { |y| y[:key] }).to eq(%w[2027 2028])
  end

  it "saves holidays and special days at any time, and offers public holidays to import" do
    year = within_tenant(company) do
      create(:public_holiday, date: "2027-02-06", name: "Chinese New Year")
      create(:public_holiday, date: "2027-05-01", name: "Labour Day")
      y = AcademicYears::Create.call(school:, start_year: 2027, start_month: 1)
      SchoolSetup.lock!(school:, year: y, section: :calendar, user: nil)
      y.holidays.create!(name: "Labour Day", starts_on: "2027-05-01", ends_on: "2027-05-01")
      y
    end
    get public_holidays_api_v1_academic_year_path(year)
    expect(json[:data].map { |h| h[:name] }).to eq([ "Chinese New Year" ])
    cny = json[:data].first

    expect do
      put holidays_api_v1_academic_year_path(year), params: {
        holidays: [ cny, { name: "June Holidays", starts_on: "2027-05-29", ends_on: "2027-06-27" } ],
        special_days: [ { date: "2027-03-05", kind: "early_dismissal", time: "11:30", description: "Sports Day" } ]
      }, as: :json
    end.not_to raise_error
    d = json[:data]
    expect(d[:holidays].map { |h| [ h[:name], h[:public_holiday], h[:operating_days_off] ] })
      .to eq([ [ "Chinese New Year", true, 0 ], [ "June Holidays", false, 20 ] ])
    expect(d[:operating_days_off]).to eq(20)
    expect(d[:special_days]).to eq([ { id: d[:special_days].first[:id], date: "2027-03-05", kind: "early_dismissal", time: "11:30", description: "Sports Day" } ])

    put holidays_api_v1_academic_year_path(year), params: { holidays: [ { name: "Bad", starts_on: "2027-03-05", ends_on: "2027-03-01" } ] }, as: :json
    expect(json.dig(:error, :message)).to eq("Holiday 1: Ends on must be on or after the start")
  end

  it "deletes a year only before it starts, for Admins" do
    year = within_tenant(company) { AcademicYears::Create.call(school:, start_year: 2026, start_month: 1) }
    later = within_tenant(company) { AcademicYears::Create.call(school:, start_year: 2027, start_month: 1) }
    delete api_v1_academic_year_path(later)
    expect(response).to have_http_status(:forbidden)

    sign_in_as(create(:user, :admin, company:))
    delete api_v1_academic_year_path(year)
    expect(json.dig(:error, :message)).to eq("AY 2026 has started and cannot be deleted")
    delete api_v1_academic_year_path(later)
    expect(response).to have_http_status(:no_content)
  end
end
