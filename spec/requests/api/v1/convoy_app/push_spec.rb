require "rails_helper"

# Convoy App › push (API-ISSUES #18, after the Driver app): each new inbox alert goes to every phone the account is signed
# in on, once, with what a tap opens; not when Notifications › Push is off; a repeated alert (same dedupe key) is not sent.
RSpec.describe "Convoy App push" do
  include ActiveJob::TestHelper

  let!(:rachel) { app_user(mobile: "9188 2045") }
  let(:account) { rachel[0] }

  def register(token, push_token, platform: "ios")
    put api_v1_convoy_app_device_path, params: { device: { platform:, push_token: } }, headers: app_as(token), as: :json
    expect(response).to have_http_status(:no_content)
  end

  def alert(key = "booking-1")
    ConvoyApp::Alerts.write([ { app_account_id: account.id, kind: "booking_confirmed", title: "SD26000141 confirmed by SimpleDrive",
                                body: "Your trip on Thu 5 Nov is confirmed.", dedupe_key: key, target: "booking", target_id: 141 } ])
  end

  it "sends a new alert to each phone once, with its target, and records pushed_at" do
    register(rachel[1], "fcm-phone")
    register(app_token(mobile: "9188 2045", device: "iPad"), "fcm-ipad", platform: "android")

    perform_enqueued_jobs { 2.times { alert } }
    row = AppNotification.sole
    data = { type: "app_alert", id: row.id.to_s, kind: "booking_confirmed", target: "booking", target_id: "141" }
    expect(fake_push.sent).to contain_exactly(
      { token: "fcm-phone", title: "SD26000141 confirmed by SimpleDrive", body: "Your trip on Thu 5 Nov is confirmed.", data: },
      { token: "fcm-ipad", title: "SD26000141 confirmed by SimpleDrive", body: "Your trip on Thu 5 Nov is confirmed.", data: }
    )
    expect(row.pushed_at).to be_present
  end

  it "keeps the alert in the inbox only when Push is off, or no phone has a token" do
    perform_enqueued_jobs { alert("a") }
    register(rachel[1], "fcm-phone")
    account.update!(notify_push: false)
    perform_enqueued_jobs { alert("b") }
    expect(fake_push.sent).to be_empty
    expect(AppNotification.pluck(:pushed_at)).to all(be_nil)
  end

  it "reports a Firebase failure without touching the inbox (raised in tests)" do
    register(rachel[1], "fcm-phone")
    fake_push.fail = true
    alert
    expect { PushJob.perform_now("app", AppNotification.ids) }.to raise_error(Push::Error)
    expect(AppNotification.sole.pushed_at).to be_nil
  end
end
