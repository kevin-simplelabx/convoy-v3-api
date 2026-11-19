require "rails_helper"

# Convoy App WebSocket: the person's own stream (alerts), only after Create Your Account.
RSpec.describe AppChannel do
  let(:account) { AppAccount.create!(first_name: "Rachel", last_name: "Tan", terms_accepted_at: Time.current) }

  it "streams the person's own signals" do
    stub_connection(driver_jwt: nil, app_jwt: ConvoyApp::IssueToken.call(account:).last)
    subscribe
    expect(subscription).to have_stream_from("app:#{account.id}")
  end

  it "waits for Create Your Account" do
    stub_connection(driver_jwt: nil, app_jwt: ConvoyApp::IssueToken.call(account: AppAccount.create!).last)
    subscribe
    expect(subscription).to be_rejected
  end
end
