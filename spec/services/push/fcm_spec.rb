require "rails_helper"

# The real Firebase client (the other specs use FakePush): the HTTP v1 message, a token Firebase no longer knows
# (:unregistered, so it is forgotten), and every other failure as Push::Error.
RSpec.describe Push::Fcm do
  let(:credentials) { instance_double(Google::Auth::ServiceAccountCredentials, access_token: "oauth-token", expires_within?: false) }
  let(:path) { "/v1/projects/convoy-test/messages:send" }

  before { allow(Google::Auth::ServiceAccountCredentials).to receive(:make_creds).and_return(credentials) }

  def stub_fcm(&block)
    stubs = Faraday::Adapter::Test::Stubs.new(&block)
    allow(Faraday).to receive(:new).and_wrap_original { |original, *args, **opts| original.call(*args, **opts) { it.adapter :test, stubs } }
  end

  def deliver = described_class.new({ type: "service_account", project_id: "convoy-test" }.to_json).deliver(token: "fcm-1", title: "Trip changed", body: "Now starts at 08:30.", data: { "kind" => "run_changed" })

  it "posts one message for Android and iOS with the OAuth token" do
    sent = nil
    stub_fcm { |s| s.post(path) { |env| sent = env; [ 200, {}, { name: "projects/convoy-test/messages/1" }.to_json ] } }
    expect(deliver).to eq(:sent)
    expect(sent.request_headers["Authorization"]).to eq("Bearer oauth-token")
    expect(JSON.parse(sent.request_body)["message"]).to eq(
      "token" => "fcm-1", "notification" => { "title" => "Trip changed", "body" => "Now starts at 08:30." }, "data" => { "kind" => "run_changed" },
      "android" => { "priority" => "high", "notification" => { "sound" => "default" } },
      "apns" => { "headers" => { "apns-priority" => "10" }, "payload" => { "aps" => { "sound" => "default" } } }
    )
  end

  it "answers :unregistered for a token Firebase no longer knows or never issued" do
    stub_fcm { |s| s.post(path) { [ 404, {}, { error: { status: "NOT_FOUND", details: [ { errorCode: "UNREGISTERED" } ] } }.to_json ] } }
    expect(deliver).to eq(:unregistered)
    stub_fcm { |s| s.post(path) { [ 400, {}, { error: { status: "INVALID_ARGUMENT", message: "The registration token is not a valid FCM registration token" } }.to_json ] } }
    expect(deliver).to eq(:unregistered)
  end

  it "raises Push::Error on other answers and when Firebase cannot be reached" do
    stub_fcm { |s| s.post(path) { [ 503, {}, { error: { status: "UNAVAILABLE" } }.to_json ] } }
    expect { deliver }.to raise_error(Push::Error, /FCM 503/)
    stub_fcm { |s| s.post(path) { raise Faraday::ConnectionFailed, "down" } }
    expect { deliver }.to raise_error(Push::Error, /ConnectionFailed/)
  end
end
