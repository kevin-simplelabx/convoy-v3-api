require "rails_helper"

# School Bus › Feasibility Studies: the school's locked fares as tiers (fare_source), Add Scenario / copy / delete (the last
# one stays), and clearing every student line at once.
RSpec.describe "School Bus feasibility scenarios, fare source and clearing students" do
  include ActiveJob::TestHelper

  let(:company) { create(:company) }
  let!(:school) { within_tenant(company) { School.create!(name: "St. Stephen's School", short_name: "SSS") } }
  let(:table) do
    { payer: "parents", basis: "distance", trip: "both", cycle: "period", distribution: "equal", one_way: { type: "pct", value: 60 },
      tiers: [ { max_km: 3, fare: 1200 }, { fare: 1500 } ], small: { on: false } }
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    fake_one_map.add("455789", 1.3138, 103.9283, "20 Siglap View")
    fake_one_map.add("460101", 1.3240, 103.9300)
    sign_in_as(create(:user, company:, permissions: %w[plans]))
  end

  def make_study
    post api_v1_feasibility_studies_path, params: { study: { name: "Siglap bid", school_mode: "prospect", prospect_name: "Siglap Primary", prospect_postal: "455789" } }
    json[:data]
  end

  def lock_fares(of: school, table: self.table)
    within_tenant(company) do
      year = AcademicYears::Create.call(school: of, start_year: 2026, start_month: 1)
      AcademicYears::SaveCalendar.call(year, { operating_days: [ 1, 2, 3, 4, 5 ], structure: "semester", period_count: 2, cca_same_as_terms: true,
                                               terms: [ { starts_on: "2026-01-05", ends_on: "2026-05-29" }, { starts_on: "2026-06-29", ends_on: "2026-11-20" } ] }, user: nil)
      FareTables::Save.call(year, table, user: nil)
      year
    end
  end

  describe "fare source" do
    it "gives the school's locked distance fares as monthly tiers" do
      year = lock_fares
      get fare_source_api_v1_feasibility_studies_path, params: { school_id: school.id }
      expect(response).to have_http_status(:ok), json.inspect
      expect(json.dig(:data, :year)).to eq(year.key)
      tiers = json.dig(:data, :tiers)
      expect(tiers.size).to eq(2)
      expect(tiers.map { it[:max_km]&.to_d }).to eq([ 3, nil ])
      expect(tiers.map { it[:fare].to_d }).to eq([ 100, 125 ]) # S$1,200 / S$1,500 a year over 12 months
      expect(tiers.map { it[:one_way_fare].to_d }).to eq([ 60, 75 ]) # 60% of the 2-way fare
    end

    it "refuses a school without locked distance fares, and a missing school" do
      get fare_source_api_v1_feasibility_studies_path, params: { school_id: school.id }
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("St. Stephen's School has no locked distance fares this year")

      within_tenant(company) { AcademicYears::Create.call(school:, start_year: 2026, start_month: 1) } # a year, but no fares yet
      get fare_source_api_v1_feasibility_studies_path, params: { school_id: school.id }
      expect(response).to have_http_status(:unprocessable_content)

      get fare_source_api_v1_feasibility_studies_path
      expect(response).to have_http_status(:bad_request).or have_http_status(:unprocessable_content)
    end

    it "keeps to the plans permission and the company's own schools" do
      lock_fares
      other = create(:company)
      theirs = within_tenant(other) { School.create!(name: "Their School", short_name: "THR") }
            get fare_source_api_v1_feasibility_studies_path, params: { school_id: theirs.id }
      expect(response).to have_http_status(:not_found)

      sign_in_as(create(:user, company:, permissions: %w[schools]))
      get fare_source_api_v1_feasibility_studies_path, params: { school_id: school.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "scenarios" do
    it "adds a blank scenario, copies one with its settings, and numbers them on" do
      study = make_study
      first = study[:scenarios].sole
      patch api_v1_feasibility_scenario_path(first[:id]), params: { scenario: { name: "Medium only", sizes: %w[MEDIUM_23], hard_cap: 20, margin_pct: 10 } }, as: :json
      expect(response).to have_http_status(:ok), json.inspect

      post scenarios_api_v1_feasibility_study_path(study[:id]), as: :json
      expect(response).to have_http_status(:created)
      added = json.dig(:data, :scenarios).last
      expect(json.dig(:data, :scenarios).size).to eq(2)
      expect(added).to include(name: "Scenario 2", status: "idle", sizes: SchoolBus::BUS_TYPES.keys.map(&:to_s))

      post scenarios_api_v1_feasibility_study_path(study[:id]), params: { from_id: first[:id] }, as: :json
      copy = json.dig(:data, :scenarios).last
      expect(copy).to include(name: "Medium only (copy)", sizes: %w[MEDIUM_23], hard_cap: 20, margin_pct: "10.0", status: "idle", result: nil)
      expect(json.dig(:data, :scenarios).size).to eq(3)
      within_tenant(company) { expect(FeasibilityScenario.where(feasibility_study_id: study[:id]).order(:position).pluck(:position)).to eq([ 1, 2, 3 ]) }
    end

    it "refuses to copy a scenario of another study, or add one to a study that is not the company's" do
      one = make_study
      two = make_study
      post scenarios_api_v1_feasibility_study_path(one[:id]), params: { from_id: two[:scenarios].sole[:id] }, as: :json
      expect(response).to have_http_status(:not_found)

      sign_in_as(create(:user, company: create(:company), permissions: %w[plans]))
      post scenarios_api_v1_feasibility_study_path(one[:id]), as: :json
      expect(response).to have_http_status(:not_found)
      sign_in_as(create(:user, company:, permissions: %w[planview]))
      post scenarios_api_v1_feasibility_study_path(one[:id]), as: :json
      expect(response).to have_http_status(:forbidden)
      within_tenant(company) { expect(FeasibilityScenario.where(feasibility_study_id: one[:id]).count).to eq(1) }
    end

    it "deletes a scenario but never the last one" do
      study = make_study
      post scenarios_api_v1_feasibility_study_path(study[:id]), as: :json
      first, second = json.dig(:data, :scenarios).pluck(:id)

      delete api_v1_feasibility_scenario_path(first)
      expect(response).to have_http_status(:no_content)
      get api_v1_feasibility_study_path(study[:id])
      expect(json.dig(:data, :scenarios).pluck(:id)).to eq([ second ])

      delete api_v1_feasibility_scenario_path(second)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Keep at least one scenario")
      delete api_v1_feasibility_scenario_path(first)
      expect(response).to have_http_status(:not_found)
    end

    it "keeps a scenario to the plans permission and its own company" do
      study = make_study
      post scenarios_api_v1_feasibility_study_path(study[:id]), as: :json
      id = json.dig(:data, :scenarios).last[:id]

      sign_in_as(create(:user, company:, permissions: %w[schools]))
      delete api_v1_feasibility_scenario_path(id)
      expect(response).to have_http_status(:forbidden)
      sign_in_as(create(:user, company: create(:company), permissions: %w[plans]))
      delete api_v1_feasibility_scenario_path(id)
      expect(response).to have_http_status(:not_found)
      within_tenant(company) { expect(FeasibilityScenario.where(id:)).to exist }
    end
  end

  describe "clearing every student line" do
    it "deletes all rows, marks results out of date, and leaves the study" do
      study = make_study
      post rows_api_v1_feasibility_study_path(study[:id]), params: { text: "460101, 6\n460101,2,AM" }
      expect(json.dig(:data, :rows).size).to eq(2)
      within_tenant(company) { FeasibilityScenario.where(feasibility_study_id: study[:id]).update_all(result: { need: 8 }, status: "done") }

      delete rows_api_v1_feasibility_study_path(study[:id])
      expect(response).to have_http_status(:ok)
      expect(json.dig(:data, :rows)).to eq([])
      expect(json.dig(:data, :geocode)).to include(postals: 0)
      expect(json.dig(:data, :scenarios).sole).to include(stale: true)
      within_tenant(company) { expect(FeasibilityRow.where(feasibility_study_id: study[:id]).count).to eq(0) }
      delete rows_api_v1_feasibility_study_path(study[:id]) # nothing left: still fine
      expect(response).to have_http_status(:ok)
    end

    it "keeps to the plans permission and the company's own study" do
      study = make_study
      post rows_api_v1_feasibility_study_path(study[:id]), params: { text: "460101, 6" }
      sign_in_as(create(:user, company:, permissions: %w[planview]))
      delete rows_api_v1_feasibility_study_path(study[:id])
      expect(response).to have_http_status(:forbidden)
      sign_in_as(create(:user, company: create(:company), permissions: %w[plans]))
      delete rows_api_v1_feasibility_study_path(study[:id])
      expect(response).to have_http_status(:not_found)
      within_tenant(company) { expect(FeasibilityRow.where(feasibility_study_id: study[:id]).count).to eq(1) }
    end
  end
end
