require "rails_helper"

# `school_bills:backfill_first_details`: first invoices issued before they had a line, the family and the bill-to code.
RSpec.describe SchoolBills::BackfillFirstDetails do
  let(:company) { create(:company) }
  let(:school) { within_tenant(company) { School.create!(name: "St. Stephen's School", lat: 1.3138, lng: 103.9283) } }

  def bill_for(child, family: nil, rider: nil)
    req = school.bus_requests.create!(child_name: child, parent_name: "Ng Mei Ling", parent_phone: "+65 8123 4410", postal: "460101", lat: 1.33, lng: 103.93,
                                      pm: false, start_on: "2027-01-04", submitted_at: 1.day.ago, level: "P1", source: "console", family:, school_rider: rider)
    # Issued before the details fix: no line, no family, no bill-to code.
    SchoolBill.create!(school:, bus_request: req, kind: "first", status: "issued", number: "INV-#{child.hash.abs}", issued_on: Date.current, bill_to: "Ng Mei Ling",
                       period_label: "Semester 1", subtotal: 504, total: 549.36, gst_amount: 45.36, gst_rate: 9)
  end

  it "adds the line, family and bill-to code, then leaves the bills alone on a second run" do
    within_tenant(company) do
      family = school.families.create!(name: "NG Family", code: "FAM-0001")
      rider = school.riders.create!(rid: "R1", name: "Ng Kai", grade: "P3", postal: "460101", lat: 1.33, lng: 103.93, source: "manual")
      FamilyRider.create!(school:, family:, rid: rider.rid)
      with_family = bill_for("Ng Jun Jie", family:)
      renewing = bill_for("Ng Kai", rider:)
      orphan = bill_for("Tan Ryan")
      done = bill_for("Lim Ann", family:)
      SchoolBills::FirstDetails.call(done)
      snapshot = lambda { SchoolBill.order(:id).map { [ it.attributes, it.lines.map(&:attributes) ] } }

      expect(described_class.call(dry_run: true)[company.code]).to have_attributes(checked: 3, updated: 3, skipped: 0)
      expect(with_family.reload.lines).to be_empty

      expect(described_class.call[company.code]).to have_attributes(checked: 3, updated: 3, skipped: 0)
      expect(with_family.reload).to have_attributes(family:, bill_to_code: "FAM-0001", total: 549.36, status: "issued")
      expect(with_family.lines.map { [ it.description, it.amount, it.child_name ] }).to eq([ [ "Ng Jun Jie | First month, Semester 1", 504, "Ng Jun Jie" ] ])
      expect(renewing.reload).to have_attributes(family:, bill_to_code: "FAM-0001")
      expect(renewing.lines.first.rid).to eq("R1")
      expect(orphan.reload).to have_attributes(family: nil, bill_to_code: nil)
      expect(orphan.lines.size).to eq(1)

      before = snapshot.call
      expect(described_class.call[company.code]).to have_attributes(checked: 1, updated: 0, skipped: 1)
      expect(snapshot.call).to eq(before)
    end
  end
end
