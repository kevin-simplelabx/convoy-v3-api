require "rails_helper"

# Fleet > Drivers and Transport Operators > Operator Drivers: tabs, invite lifecycle, View Details, customer-facing copy.
RSpec.describe "Fleet drivers" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:admin) { create(:user, :admin, company:) }
  let!(:f) do
    within_tenant(company) do
      hup = create(:operator, name: "Hup Seng")
      { hup:, van: create(:vehicle, plate: "PD1A"), van2: create(:vehicle, plate: "PD2B"),
        op_bus: create(:vehicle, plate: "PC1X", operator: hup), other_op: create(:operator, name: "Other") }
    end
  end

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(admin)
  end

  def tenant(&) = within_tenant(company, &)

  describe "own drivers" do
    it "invites with a normalised mobile, records the SMS and refuses a live duplicate" do
      post api_v1_drivers_path, params: { driver: { name: "Eric Pang", phone: "9123 4567" } }, as: :json
      expect(response).to have_http_status(:created), json.inspect
      expect(json[:data]).to include(phone: "+6591234567", phone_display: "+65 9123 4567", status: "pending")
      expect(json.dig(:meta, :message)).to eq("SimpleDrive invited you to drive with them on Convoy. Download Convoy Driver to accept")
      expect(tenant { DriverInvite.count }).to eq(1)

      post api_v1_drivers_path, params: { driver: { name: "Copy", phone: "+65 91234567" } }, as: :json
      expect(json.dig(:error, :details, :phone)).to include("Phone is already used by Eric Pang")

      post api_v1_drivers_path, params: { driver: { name: "Bad", phone: "123" } }, as: :json
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "walks the tabs: accept, remove, invite again, decline, delete" do
      id = tenant { create(:driver, name: "Tan", status: :pending, phone: "+6591112222").id }

      patch resend_api_v1_driver_path(id)
      expect(tenant { DriverInvite.where(kind: "resend").count }).to eq(1)

      patch accept_api_v1_driver_path(id)
      expect(json[:data]).to include(status: "active", kyc_shared: false)

      # mobile is the driver's once accepted
      patch api_v1_driver_path(id), params: { driver: { phone: "+6598887777" } }, as: :json
      expect(json.dig(:error, :details, :phone)).to include("Phone can only be changed by the driver in the Convoy Driver app")

      delete api_v1_driver_path(id)
      expect(json.dig(:error, :message)).to eq("Remove Tan first. Active drivers move to Past Drivers")

      tenant do
        Driver.find(id).then do |d|
          f[:van].driver_schedules.create!(driver: d, starts_on: Date.current - 30)
          f[:van2].driver_schedules.create!(driver: d, starts_on: Date.current + 5)
        end
      end
      get api_v1_drivers_path
      row = json[:data].find { |d| d[:id] == id }
      expect(row[:vehicle]).to include(plate: "PD1A", since: "2026-10-03")
      expect(row[:upcoming]).to eq([ { vehicle_id: f[:van2].id, plate: "PD2B", starts_on: "2026-11-07" } ])

      patch remove_api_v1_driver_path(id)
      expect(json[:data]).to include(status: "past", last_vehicle: { id: f[:van].id, plate: "PD1A" })
      tenant do
        expect(f[:van].default_driver_on(Date.current)).to be_nil
        expect(f[:van2].reload.driver_schedules.last.driver_id).to be_nil
      end

      patch decline_api_v1_driver_path(id)
      expect(json.dig(:error, :message)).to eq("Tan is past, so this can't be done")

      patch reinvite_api_v1_driver_path(id)
      expect(json[:data]).to include(status: "pending", responded_at: nil)
      patch decline_api_v1_driver_path(id)
      expect(json[:data][:status]).to eq("declined")

      get api_v1_drivers_path, params: { status: "declined" }
      expect(json.dig(:meta, :counts)).to eq(pending: 0, active: 0, declined: 1, past: 0)

      delete api_v1_driver_path(id)
      expect(response).to have_http_status(:no_content)
      get api_v1_drivers_path, params: { status: "declined" }
      expect(json[:data]).to be_empty

      # the number is free again
      post api_v1_drivers_path, params: { driver: { name: "Tan again", phone: "+6591112222" } }, as: :json
      expect(response).to have_http_status(:created)
    end

    it "searches name and mobile within the tab counts" do
      tenant do
        create(:driver, name: "Ahmad", phone: "+6591230001")
        create(:driver, name: "Bala", phone: "+6598760002", status: :pending)
      end
      get api_v1_drivers_path, params: { q: "9876" }
      expect(json[:data]).to be_empty
      expect(json.dig(:meta, :counts)).to include(active: 0, pending: 1)
    end

    it "shows what the driver shared, masked until asked, and sets the customer-facing name" do
      id = tenant do
        d = create(:driver, name: "Siti")
        d.create_kyc_profile!(company:, id_number: "S1234567D", residential_status: "Singapore Citizen",
                              date_of_birth: Date.new(1980, 12, 1), vocational_licence_expires_on: Date.current + 30)
        d.id
      end
      get details_api_v1_driver_path(id)
      expect(json.dig(:data, :kyc)).to include(id_label: "NRIC", id_number: "S****567D", age: 45, vocational_status: "due_soon")

      get details_api_v1_driver_path(id), params: { reveal_id: true }
      expect(json.dig(:data, :kyc, :id_number)).to eq("S1234567D")
      expect(tenant { DriverKycProfile.last.audits.last.comment }).to eq("Full NRIC shown")
      expect(ActiveRecord::Base.connection.select_value("SELECT id_number FROM driver_kyc_profiles")).not_to include("S1234567D")

      photo = fixture_file_upload(Rails.root.join("db/seeds/files/fleet/drv-1.png"), "image/png")
      patch display_api_v1_driver_path(id), params: { display_name: " Siti ", display_photo: photo }
      expect(json.dig(:data, :display)).to include(name: "Siti", set_by: admin.name), json.inspect
      expect(json.dig(:data, :display, :photo, :url)).to start_with("/api/v1/downloads/")

      patch display_api_v1_driver_path(id), params: { display_name: "", remove_display_photo: true }
      expect(json.dig(:data, :display)).to be_nil
    end
  end

  describe "operator drivers" do
    it "invites with the operator in the SMS and leaves the bus when the operator changes" do
      post api_v1_operator_drivers_path, params: { operator_driver: { name: "Muthu", phone: "81234567", operator_id: f[:hup].id } }, as: :json
      expect(json.dig(:meta, :message)).to eq("Invited to connect with Hup Seng, managed by SimpleDrive. Download Convoy Driver to accept")
      id = json.dig(:data, :id)

      patch accept_api_v1_operator_driver_path(id)
      patch assign_vehicle_api_v1_operator_driver_path(id), params: { vehicle_id: f[:op_bus].id }, as: :json
      expect(json.dig(:data, :vehicle_plate)).to eq("PC1X")

      patch api_v1_operator_driver_path(id), params: { operator_driver: { operator_id: f[:other_op].id } }, as: :json
      expect(json[:data]).to include(operator_name: "Other", vehicle_id: nil)
    end

    it "keeps the last bus when removed" do
      id = tenant { create(:operator_driver, operator: f[:hup], vehicle: f[:op_bus]).id }
      patch remove_api_v1_operator_driver_path(id)
      expect(json[:data]).to include(status: "past", vehicle_id: nil, last_vehicle: { id: f[:op_bus].id, plate: "PC1X" })
    end
  end
end
