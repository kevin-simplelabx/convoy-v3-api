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

  it "numbers family codes per school, so two schools both start at FAM-0001" do
    other = within_tenant(company) { School.create!(name: "Other School", short_name: "OTH") }
    post api_v1_school_families_path(school), params: { family: { name: "Tan Family", name_mode: "custom" } }
    expect(json[:data]).to include(code: "FAM-0001")
    post api_v1_school_families_path(other), params: { family: { name: "Lim Family", name_mode: "custom" } }
    expect(json[:data]).to include(code: "FAM-0001")
    post api_v1_school_families_path(school), params: { family: { name: "Koh Family", name_mode: "custom" } }
    expect(json[:data]).to include(code: "FAM-0002")
  end

  it "adds a family named after the father, links riders and searches" do
    post api_v1_school_families_path(school), params: { guardian: { first_name: "Ah Kow", last_name: "Tan", relationship: "Father", phone: "9123 4567" } }
    fam = json[:data]
    expect(fam).to include(code: "FAM-0001", name: "TAN Family", name_mode: "auto")

    post guardians_api_v1_family_path(fam[:id]), params: { guardian: { first_name: "Mei", relationship: "Mother", phone: "12" } }
    expect(json.dig(:error, :message)).to eq("Phone doesn't look like a phone number")
    post guardians_api_v1_family_path(fam[:id]), params: { guardian: { first_name: "", last_name: "", relationship: "Mother" } }
    expect(json[:error]).to include(message: "Enter a first name or last name", details: { first: [ "Enter a first name or last name" ], last: [ "Enter a first name or last name" ] })

    get candidates_api_v1_family_path(fam[:id])
    expect(json[:data].map { |c| [ c[:rid], c[:match] ] }).to eq([ %w[S2 parent], %w[S1 parent], [ "S3", nil ] ])
    post riders_api_v1_family_path(fam[:id]), params: { rids: %w[S1 S2] }
    expect(json.dig(:data, :riders).map { |r| r[:rid] }).to eq(%w[S1 S2])

    post api_v1_school_families_path(school), params: { family: { name: "", name_mode: "custom" } }
    expect(json.dig(:error, :message)).to eq("Family name is required")
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
    expect(json.dig(:data, :warnings)).to include("Line 3: not-an-email doesn't look like an email, left out", "Line 4: student S9 is not on the rider list")

    get export_api_v1_school_families_path(school)
    lines = response.body.lines.map(&:strip)
    expect(lines.first).to eq("family_id,family_name,guardian_name,relationship,phone,email,student_id,student_name")
    expect(lines).to include("FAM-0009,LIM Family,Lim Boon,Father,98887777,,S9,")
  end

  it "offers only riders without a family as candidates: parent matches first, then by name" do
    post api_v1_school_families_path(school), params: { guardian: { first_name: "Ah Kow", last_name: "Tan", relationship: "Father", phone: "9123 4567" } }
    fam = json[:data]
    post api_v1_school_families_path(school), params: { family: { name: "Lim household", name_mode: "custom" } }
    post riders_api_v1_family_path(json.dig(:data, :id)), params: { rids: %w[S2] }

    get candidates_api_v1_family_path(fam[:id])
    expect(json[:data].map { |c| [ c[:rid], c[:match] ] }).to eq([ %w[S1 parent], [ "S3", nil ] ])
  end

  it "imports with groups made inside the file, left-out phones and emails, and only the families it emptied deleted" do
    within_tenant(company) do
      emptied = school.families.create!(code: "FAM-0050", name: "Emptied", name_mode: "custom")
      kept = school.families.create!(code: "FAM-0051", name: "Kept", name_mode: "custom")
      kept.guardians.create!(first_name: "Kept", last_name: "Parent")
      school.families.create!(code: "FAM-0052", name: "Already empty", name_mode: "custom")
      Families.link(emptied, school, %w[S1])
      Families.link(kept, school, %w[S2])
      school.families.create!(code: "FAM-0053", name: "Chan Family", name_mode: "custom") # same name as in the file: not matched
    end
    csv = <<~CSV
      family_id,family_name,guardian_name,relationship,phone,email,student_id,student_name
      ,Chan Family,Chan Mei,Mother,12,bad@mail,S1,
      ,Chan Family,Chan Boy,,91112222,boy@mail.com,S2,
      ,,Wong Lee,,93334444,,,
      ,,Wong Lee,,93334444,,S3,
    CSV
    post import_api_v1_school_families_path(school), params: { text: csv }
    expect(json[:data]).to include(families_added: 2, guardians_added: 3, guardians_updated: 1, riders_linked: 3, families_deleted: 1)
    expect(json.dig(:data, :warnings)).to eq([ "1 families lost all their riders but still have guardians. Review or delete them",
                                               "Line 2: 12 doesn't look like a phone number, left out", "Line 2: bad@mail doesn't look like an email, left out" ])

    within_tenant(company) do
      expect(Family.pluck(:code)).to contain_exactly("FAM-0051", "FAM-0052", "FAM-0053", "FAM-0054", "FAM-0055")
      chan = Family.find_by!(code: "FAM-0054")
      expect(chan.name).to eq("Chan Family")
      expect(chan.guardians.map { [ it.name, it.relationship, it.phone ] }).to eq([ [ "Chan Mei", "Mother", nil ], [ "Chan Boy", "Guardian", "91112222" ] ])
      expect(chan.family_riders.pluck(:rid)).to contain_exactly("S1", "S2")
      wong = Family.find_by!(code: "FAM-0055")
      expect(wong.name).to eq("Wong Lee")
      expect(wong.family_riders.pluck(:rid)).to eq(%w[S3])
    end
  end
end
