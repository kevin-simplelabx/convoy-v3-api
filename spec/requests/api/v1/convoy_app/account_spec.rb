require "rails_helper"

# Convoy App › Account: profile and notification switches, Delete Account (30-day grace, signing in again cancels it,
# purge job incl. abandoned accounts), device push token, Suggest Convoy to My Company.
RSpec.describe "Convoy App account" do
  let!(:rachel) { app_user(mobile: "9188 2045") }
  let(:account) { rachel[0] }
  let(:token) { rachel[1] }

  def live_jwt(account) = account.jwts.create!(jti: SecureRandom.uuid, exp: 1.day.from_now)

  describe "profile" do
    it "shows the account and saves the name order and the notification switches, audited as the person" do
      get api_v1_convoy_app_profile_path, headers: app_as(token)
      expect(json[:data]).to include(id: account.id, display_name: "Rachel Tan", name_order: "first", profile_complete: true, needs_identity: false,
                                     notifications: { push: true, sms: false, email: true })

      patch api_v1_convoy_app_profile_path, params: { profile: { name_order: "last", notify_sms: true, notify_email: false } }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(display_name: "Tan Rachel", notifications: { push: true, sms: true, email: false })
      expect(account.audits.last).to have_attributes(user: account)
    end

    it "keeps the name required once Create Your Account is done" do
      patch api_v1_convoy_app_profile_path, params: { profile: { first_name: "" } }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(account.reload.first_name).to eq("Rachel")
    end
  end

  describe "Delete Account" do
    it "signs every phone out, records the date, tells the person by email and keeps the account for 30 days" do
      add = app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      second_phone = app_token(mobile: "9188 2045", device: "iPad")
      expect(add).to be_present

      freeze_time do
        expect { delete api_v1_convoy_app_profile_path, headers: app_as(second_phone) }
          .to have_enqueued_mail(AppMailer, :delete_requested).with("rachel@gmail.com", 30.days.from_now.to_date)
        expect(response).to have_http_status(:ok)
        expect(json[:data]).to eq(delete_on: 30.days.from_now.to_date.iso8601)
        expect(account.reload.delete_requested_at).to be_within(1.second).of(Time.current)
      end
      expect(account.jwts).to be_empty
      get api_v1_convoy_app_session_path, headers: app_as(token)
      expect(response).to have_http_status(:unauthorized)
      expect(AppAccount.exists?(account.id)).to be(true)
    end

    it "is cancelled by signing in again, and the purge job then keeps the account" do
      delete api_v1_convoy_app_profile_path, headers: app_as(token)
      travel 20.days
      app_token(mobile: "9188 2045")
      expect(json.dig(:data, :account, :delete_requested_at)).to be_nil
      expect(account.reload.delete_requested_at).to be_nil

      travel 20.days
      expect { AppAccountsPurgeJob.perform_now }.not_to change(AppAccount, :count)
    end

    it "is purged after 30 days with its identities and sign-ins; the moves log stays" do
      other = create(:app_account, first_name: "David", mobile: "+6591773301", email: "david@gmail.com")
      app_add_identity(token, kind: "mobile", value: "9177 3301", replace: true)
      expect(AppIdentityMove.last.to_app_account_id).to eq(account.id)
      delete api_v1_convoy_app_profile_path, headers: app_as(token)

      travel 29.days
      expect { AppAccountsPurgeJob.perform_now }.not_to change(AppAccount, :count)
      travel 2.days
      expect { AppAccountsPurgeJob.perform_now }.to change(AppAccount, :count).by(-1)
      expect(AppAccount.exists?(account.id)).to be(false)
      expect(AppIdentity.where(app_account_id: account.id)).to be_empty
      expect(AppJwt.where(app_account_id: account.id)).to be_empty
      expect(AppIdentityMove.last).to have_attributes(to_app_account_id: nil, from_app_account_id: other.id)
    end

    it "skips an account that signed in again while the job was running" do
      delete api_v1_convoy_app_profile_path, headers: app_as(token)
      travel 31.days
      scope = AppAccount.due_for_deletion
      expect(scope).to include(account)
      # the account is picked up, then the person signs in (clears the date) before its row is locked
      allow(AppAccount).to receive(:due_for_deletion).and_return(scope)
      allow(scope).to receive(:find_each).and_wrap_original do |m, &blk|
        m.call { |a| AppAccount.where(id: a.id).update_all(delete_requested_at: nil); blk.call(a) }
      end
      expect { AppAccountsPurgeJob.perform_now }.not_to change(AppAccount, :count)
    end
  end

  describe "abandoned accounts" do
    it "purges accounts nobody can come back to and keeps signed-in, returnable and young ones" do
      old = 40.days.ago
      unfinished = create(:app_account, :unfinished, created_at: old, mobile: "+6591000001")
      no_identity = create(:app_account, created_at: old)
      keep_returnable = create(:app_account, created_at: old, mobile: "+6591000003")
      keep_signed_in_empty = create(:app_account, created_at: old).tap { live_jwt(it) }
      keep_signed_in_unfinished = create(:app_account, :unfinished, created_at: old, mobile: "+6591000005").tap { live_jwt(it) }
      keep_young = create(:app_account, :unfinished, created_at: 5.days.ago, mobile: "+6591000006")
      expired_only = create(:app_account, created_at: old).tap { it.jwts.create!(jti: SecureRandom.uuid, exp: 1.hour.ago) }

      expect(AppAccount.abandoned).to match_array([ unfinished, no_identity, expired_only ])
      AppAccountsPurgeJob.perform_now
      expect(AppAccount.where(id: [ unfinished, no_identity, expired_only ])).to be_empty
      expect(AppAccount.all).to match_array([ account, keep_returnable, keep_signed_in_empty, keep_signed_in_unfinished, keep_young ])
    end

    it "clears expired sign-ins (with their push tokens) and old codes by the recurring command" do
      old = account.jwts.create!(jti: SecureRandom.uuid, exp: 1.hour.ago)
      AppDevice.create!(app_account: account, app_jwt: old, platform: "ios", push_token: "old-phone")
      AppSignInCode.issue!("+6591773301", purpose: :sign_in)
      travel 3.days
      command = YAML.load_file(Rails.root.join("config/recurring.yml"), aliases: true).dig("production", "clear_expired_sign_ins", "command")
      eval(command) # rubocop:disable Security/Eval
      expect(AppJwt.where(id: old.id)).to be_empty
      expect(AppDevice.count).to eq(0)
      expect(AppSignInCode.count).to eq(0)
    end
  end

  describe "device push token" do
    let(:body) { { device: { platform: "ios", push_token: "fcm-token-1" } } }

    it "registers it with this sign-in, replaces it, and removes it" do
      put api_v1_convoy_app_device_path, params: body, headers: app_as(token), as: :json
      expect(response).to have_http_status(:no_content)
      expect(AppDevice.all.map { [ it.app_account_id, it.platform, it.push_token ] }).to eq([ [ account.id, "ios", "fcm-token-1" ] ])

      put api_v1_convoy_app_device_path, params: { device: { platform: "android", push_token: "fcm-token-2" } }, headers: app_as(token), as: :json
      expect(AppDevice.all.map { [ it.platform, it.push_token ] }).to eq([ %w[android fcm-token-2] ])

      delete api_v1_convoy_app_device_path, headers: app_as(token)
      expect(response).to have_http_status(:no_content)
      expect(AppDevice.count).to eq(0)
    end

    it "accepts flat params too" do
      put api_v1_convoy_app_device_path, params: { platform: "ios", push_token: "flat-1" }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:no_content), response.body
      expect(AppDevice.pluck(:push_token)).to eq([ "flat-1" ])
    end

    it "moves a token to the sign-in that registered it last, and keeps one row per phone" do
      put api_v1_convoy_app_device_path, params: body, headers: app_as(token), as: :json
      other_account, other_token = app_user(mobile: "9177 3301", name: %w[David Tan])
      put api_v1_convoy_app_device_path, params: body, headers: app_as(other_token), as: :json
      expect(AppDevice.all.map { [ it.app_account_id, it.push_token ] }).to eq([ [ other_account.id, "fcm-token-1" ] ])
    end

    it "refuses an unknown platform or a missing token, and goes with a sign-out" do
      put api_v1_convoy_app_device_path, params: { device: { platform: "palm", push_token: "x" } }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      put api_v1_convoy_app_device_path, params: { device: { platform: "ios" } }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:unprocessable_content).or have_http_status(:bad_request)

      put api_v1_convoy_app_device_path, params: body, headers: app_as(token), as: :json
      delete api_v1_convoy_app_session_path, headers: app_as(token)
      expect(AppDevice.count).to eq(0)
    end

    it "needs a sign-in, and works before Create Your Account" do
      put api_v1_convoy_app_device_path, params: body, as: :json
      expect(response).to have_http_status(:unauthorized)
      fresh = app_token(mobile: "9177 3301")
      put api_v1_convoy_app_device_path, params: body, headers: app_as(fresh), as: :json
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "Suggest Convoy to My Company" do
    let!(:work) { create(:app_identity, :work, app_account: account, value: "rachel@acme.com") }

    def suggest(**params) = post(api_v1_convoy_app_company_suggestions_path, params: { identity_id: work.id, company_name: "Acme Pte Ltd" }.merge(params),
                                                                              headers: app_as(token), as: :json)

    it "creates a Company Lead for Convoy Admin, naming the person only when they agree" do
      expect { suggest(contact: " Mei, HR ") }.to change(CompanyLead, :count).by(1)
      expect(response).to have_http_status(:created)
      expect(json[:data]).to include(company_name: "Acme Pte Ltd", domain: "acme.com", named: false)
      expect(CompanyLead.last).to have_attributes(domain: "acme.com", contact: "Mei, HR", named_name: nil, named_via: nil, source: "Convoy app",
                                                  asked_at: be_present)

      suggest(named: true)
      expect(json.dig(:data, :named)).to be(true)
      expect(CompanyLead.last).to have_attributes(named_name: "Rachel Tan", named_via: "rachel@acme.com")
    end

    it "needs a work email of the person's own and a company name" do
      suggest(identity_id: account.identities.find_by(kind: "mobile").id)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Suggest Convoy from a work email")

      suggest(company_name: "  ")
      expect(json.dig(:error, :details)).to eq(company_name: [ "can't be blank" ])

      stranger = create(:app_identity, :work)
      suggest(identity_id: stranger.id)
      expect(response).to have_http_status(:not_found)
      expect(CompanyLead.count).to eq(0)
    end
  end
end
