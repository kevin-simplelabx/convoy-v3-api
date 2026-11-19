require "rails_helper"

# Fleet > Transport Operators > Operator Drivers: the row buttons (Resend, Accept, Decline, Invite Again), View Details
# (NRIC masked until asked) and the customer-facing name and photo, with the vehicles permission and per company.
RSpec.describe "Fleet operator driver invites" do
  let(:company) { create(:company, name: "SimpleDrive") }
  let(:admin) { create(:user, :admin, company:) }
  let(:hup) { within_tenant(company) { create(:operator, name: "Hup Seng") } }

  before do
    travel_to Time.zone.local(2026, 11, 2, 9, 0)
    sign_in_as(admin)
  end

  let(:now) { "2026-11-02T09:00:00+08:00" }

  def tenant(&) = within_tenant(company, &)
  def driver(status = :pending) = tenant { create(:operator_driver, operator: hup, name: "Muthu", status:, invited_at: 2.days.ago).id }
  def resends(id) = tenant { DriverInvite.where(invitable_type: "OperatorDriver", invitable_id: id, kind: "resend").to_a }

  it "resends a pending invite with the operator in the SMS, and only while pending" do
    id = driver
    patch resend_api_v1_operator_driver_path(id)
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to include(status: "pending", invited_at: now)
    expect(resends(id).sole).to have_attributes(sent_by_id: admin.id, message: "Invited to connect with Hup Seng, managed by SimpleDrive. Download Convoy Driver to accept")

    patch accept_api_v1_operator_driver_path(id)
    patch resend_api_v1_operator_driver_path(id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Muthu is active, so this can't be done")
    expect(resends(id).size).to eq(1)
  end

  it "accepts a pending driver once" do
    id = driver
    patch remove_api_v1_operator_driver_path(id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Muthu is pending, so this can't be done")

    patch accept_api_v1_operator_driver_path(id)
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to include(status: "active", responded_at: now, joined_at: now, left_at: nil)
    expect(tenant { OperatorDriver.find(id).status }).to eq("active")

    patch accept_api_v1_operator_driver_path(id)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Muthu is active, so this can't be done")
  end

  it "declines a pending driver, refuses a past one, and invites again" do
    past = driver(:past)
    patch decline_api_v1_operator_driver_path(past)
    expect(json.dig(:error, :message)).to eq("Muthu is past, so this can't be done")

    patch reinvite_api_v1_operator_driver_path(past)
    expect(json[:data]).to include(status: "pending", invited_at: now, responded_at: nil, joined_at: nil, left_at: nil)
    expect(resends(past).size).to eq(1)

    patch decline_api_v1_operator_driver_path(past)
    expect(response).to have_http_status(:ok)
    expect(json[:data]).to include(status: "declined", responded_at: now)

    patch reinvite_api_v1_operator_driver_path(past)
    expect(json[:data]).to include(status: "pending")
    patch accept_api_v1_operator_driver_path(past)
    patch reinvite_api_v1_operator_driver_path(past)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Muthu is active, so this can't be done")
  end

  it "shows what the driver shared, masked until asked, with an audit when shown in full" do
    id = driver(:active)
    get details_api_v1_operator_driver_path(id)
    expect(json[:data]).to include(driver: hash_including(id:, operator_name: "Hup Seng", kyc_shared: false), kyc: nil)

    tenant { OperatorDriver.find(id).create_kyc_profile!(company:, id_number: "G1234567N", residential_status: "Work Permit", date_of_birth: Date.new(1990, 1, 5)) }
    get details_api_v1_operator_driver_path(id)
    expect(json.dig(:data, :kyc)).to include(id_number: "G****567N", age: 36)
    expect(tenant { DriverKycProfile.last.audits.where.not(comment: nil).count }).to eq(0)

    get details_api_v1_operator_driver_path(id), params: { reveal_id: true }
    expect(json.dig(:data, :kyc, :id_number)).to eq("G1234567N")
    expect(tenant { DriverKycProfile.last.audits.last }).to have_attributes(comment: "Full FIN shown", user_id: admin.id)
  end

  it "sets and clears the customer-facing name and photo" do
    id = driver(:active)
    photo = fixture_file_upload(Rails.root.join("db/seeds/files/fleet/drv-1.png"), "image/png")
    patch display_api_v1_operator_driver_path(id), params: { display_name: " Uncle Muthu ", display_photo: photo }
    expect(json.dig(:data, :display)).to include(name: "Uncle Muthu", set_by: admin.name), json.inspect
    expect(json.dig(:data, :display, :photo, :url)).to start_with("/api/v1/downloads/")

    patch display_api_v1_operator_driver_path(id), params: { display_name: "", remove_display_photo: true }
    expect(json.dig(:data, :display)).to be_nil
    expect(tenant { OperatorDriver.find(id).slice(:display_name, :display_set_by_id) }).to eq("display_name" => nil, "display_set_by_id" => nil)
  end

  it "needs the vehicles permission to change, and keeps other companies out" do
    id = driver
    sign_in_as(create(:user, company:, permissions: %w[finance]))
    %i[resend accept decline reinvite remove display].each do |action|
      patch public_send(:"#{action}_api_v1_operator_driver_path", id)
      expect(response).to have_http_status(:forbidden), action.to_s
    end
    get details_api_v1_operator_driver_path(id) # read by everyone in the company
    expect(response).to have_http_status(:ok)

    sign_in_as(create(:user, :admin, company: create(:company)))
    %i[resend accept decline reinvite remove display].each do |action|
      patch public_send(:"#{action}_api_v1_operator_driver_path", id)
      expect(response).to have_http_status(:not_found), action.to_s
    end
    get details_api_v1_operator_driver_path(id)
    expect(response).to have_http_status(:not_found)
    expect(tenant { OperatorDriver.find(id).status }).to eq("pending")
  end
end
