require "rails_helper"

# Driver app WebSocket: the driver's own stream; closes when the sign-in ends.
RSpec.describe DriverChannel do
  let(:jwt) { DriverApp::IssueToken.call(account: DriverAccount.create!(phone: "+6591234567")).last }

  it "streams the driver's own signals" do
    stub_connection(driver_jwt: jwt, app_jwt: nil)
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("driver:#{jwt.driver_account_id}")
  end

  it "refuses a Convoy App socket" do
    stub_connection(driver_jwt: nil, app_jwt: nil)
    subscribe
    expect(subscription).to be_rejected
  end
end
