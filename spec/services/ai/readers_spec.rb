require "rails_helper"

RSpec.describe "Ai readers" do
  it "cleans a log card reply" do
    fake_claude.reply = { is_log_card: true, plate: "pd 3318 k", make: "Toyota", model: "HiAce", year_made: "2023",
                          registered_on: "2023-02-14", chassis_number: "trh223-1", engine_number: "", coe_expires_on: "14/02/2033",
                          road_tax_expires_on: "2026-12-31", seats: "13 seats" }
    data, = Ai::Readers::LogCard.read(text: "card")
    expect(data).to eq(plate: "PD3318K", make: "Toyota", model: "HiAce", year_made: 2023, registered_on: "2023-02-14",
                       chassis_number: "TRH223-1", road_tax_expires_on: "2026-12-31", seats: 13)
  end

  it "rejects a document that is not a log card" do
    fake_claude.reply = { is_log_card: false }
    expect { Ai::Readers::LogCard.read(text: "x") }.to raise_error(ApplicationService::Error, /log card/)
  end

  it "cleans an insurance reply" do
    fake_claude.reply = { is_insurance: true, kind: "invoice", plate: "PC7475L", insurer: "Income Insurance Limited",
                          premium: "S$ 2,450.00", gst: "220.50", total: "2670.5", ends_on: "2027-03-31", starts_on: "" }
    data, = Ai::Readers::Insurance.read(text: "x")
    expect(data).to include(kind: "invoice", premium: "2450.0", gst: "220.5", total: "2670.5", ends_on: "2027-03-31")
    expect(data).not_to have_key(:starts_on)
  end
end
