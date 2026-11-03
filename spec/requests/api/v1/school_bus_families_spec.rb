require "rails_helper"

# School Bus › Families & Riders: families named after a parent, guardians (checks), linking riders (parent matches
# first, one family per rider), search, unlinked riders, CSV import / export, Add New Rider into a family.
RSpec.describe "School Bus families" do
  let(:company) { create(:company) }
  let!(:school) do
    within_tenant(company) do
      s = School.create!(name: "St. Stephen's School", short_name: "SSS")
      [ [ "S1", "Tan Wei Ling", "Tan Ah Kow", "91234567" ], [ "S2", "Tan Jun Hao", "Tan Ah Kow", "+65 9123 4567" ], [ "S3", "Lim Mei", "Lim Boon", "98887777" ] ]
        .each { |rid, name, parent, contact| s.riders.create!(rid:, name:, postal: "460101", parent_name: parent, parent_contact: contact, source: "manual") }
      s
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(create(:user, company:, permissions: %w[schools]))
  end

  it "adds a family named after the father, links riders and searches" do
    post api_v1_school_families_path(school), params: { guardian: { first_name: "Ah Kow", last_name: "Tan", relationship: "Father", phone: "9123 4567" } }
    fam = json[:data]
    expect(fam).to include(code: "FAM-0001", name: "TAN Family", name_mode: "auto")

    post guardians_api_v1_family_path(fam[:id]), params: { guardian: { first_name: "Mei", relationship: "Mother", phone: "12" } }
    expect(json.dig(:error, :message)).to eq("Phone doesn't look like a phone number")

    get candidates_api_v1_family_path(fam[:id])
    expect(json[:data].map { |c| [ c[:rid], c[:match] ] }).to eq([ %w[S2 parent], %w[S1 parent], [ "S3", nil ] ])
    post riders_api_v1_family_path(fam[:id]), params: { rids: %w[S1 S2] }
    expect(json.dig(:data, :riders).map { |r| r[:rid] }).to eq(%w[S1 S2])

    post api_v1_school_families_path(school), params: { family: { name: "Lim household", name_mode: "custom" } }
    other = json[:data]
    post riders_api_v1_family_path(other[:id]), params: { rids: %w[S2 S3] }
    get api_v1_family_path(fam[:id])
    expect(json.dig(:data, :riders).map { |r| r[:rid] }).to eq(%w[S1]) # S2 moved: one family per rider at a school

    get api_v1_school_families_path(school), params: { q: "4567" }
    expect(json[:data].map { |f| f[:code] }).to eq(%w[FAM-0001])
    get api_v1_school_families_path(school), params: { q: "Mei" }
    expect(json[:data].map { |f| f[:name] }).to eq([ "Lim household" ])
    expect(json.dig(:meta, :unlinked_riders)).to eq(0)

    post api_v1_school_riders_path(school), params: { rider: { first_name: "Wei", last_name: "Tan", postal: "460101" }, family_id: fam[:id] }
    get api_v1_family_path(fam[:id])
    expect(json.dig(:data, :riders).map { |r| r[:name] }).to eq([ "Tan Wei Ling", "Tan Wei" ])

    patch api_v1_family_path(fam[:id]), params: { family: { code: "fam-0002" } }
    expect(json.dig(:error, :message)).to eq("Code has already been taken")
  end

  it "imports and exports families as CSV" do
    csv = <<~CSV
      family_id,family_name,guardian_name,relationship,phone,email,student_id,student_name
      ,TAN Family,Tan Ah Kow,Father,91234567,ahkow@example.com,S1,Tan Wei Ling
      ,TAN Family,Lee Siew,Mother,92223333,not-an-email,S2,Tan Jun Hao
      FAM-0009,LIM Family,Lim Boon,Father,98887777,,S9,Nobody
      ,,,,,,,
    CSV
    post import_api_v1_school_families_path(school), params: { text: csv }
    expect(json[:data]).to include(families_added: 2, guardians_added: 3, riders_linked: 3, skipped: 1)
    expect(json.dig(:data, :warnings)).to include("Line 3: not-an-email doesn't look like an email", "Line 4: student S9 is not on the rider list")

    get export_api_v1_school_families_path(school)
    lines = response.body.lines.map(&:strip)
    expect(lines.first).to eq("family_id,family_name,guardian_name,relationship,phone,email,student_id,student_name")
    expect(lines).to include("FAM-0009,LIM Family,Lim Boon,Father,98887777,,S9,")
  end
end
