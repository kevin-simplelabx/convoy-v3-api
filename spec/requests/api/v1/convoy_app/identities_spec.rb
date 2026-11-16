require "rails_helper"

# Convoy App › Account › Mobile and Emails: add / change / re-verify / remove a mobile or email with a code, free-mail
# is never a work email, one personal per kind, one work email per domain, a mobile moves between accounts, an email never.
RSpec.describe "Convoy App identities" do
  let!(:rachel) { app_user(mobile: "9188 2045") }
  let(:account) { rachel[0] }
  let(:token) { rachel[1] }

  def values = AppAccount.find(account.id).identities.map { [ it.kind, it.tag, it.value ] }

  it "lists every identity with its use and, for a work email, its next check" do
    app_add_identity(token, kind: "email", value: "Rachel@Gmail.com")
    app_add_identity(token, kind: "email", value: "rachel@google.com", tag: "work")
    get api_v1_convoy_app_identities_path, headers: app_as(token)
    expect(response).to have_http_status(:ok)
    expect(json[:data].map { it.slice(:kind, :tag, :value, :display, :domain, :reverify_state, :uses) }).to eq(
      [ { kind: "email", tag: "personal", value: "rachel@gmail.com", display: "rachel@gmail.com", domain: "gmail.com", reverify_state: nil, uses: [] },
        { kind: "email", tag: "work", value: "rachel@google.com", display: "rachel@google.com", domain: "google.com", reverify_state: "ok", uses: [] },
        { kind: "mobile", tag: "personal", value: "+6591882045", display: "+65 9188 2045", domain: nil, reverify_state: nil, uses: [] } ]
    )
    expect(json.dig(:data, 1, :reverify_due_on)).to eq(12.months.from_now.to_date.iso8601)
  end

  describe "add" do
    it "adds a personal email and a work email, each with its code" do
      app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(outcome: "added", identity: hash_including(kind: "email", tag: "personal", value: "rachel@gmail.com"))
      expect(json.dig(:data, :identities).size).to eq(2)

      app_add_identity(token, kind: "email", value: "rachel@google.com", tag: "work")
      expect(json.dig(:data, :outcome)).to eq("added")
      app_add_identity(token, kind: "email", value: "rachel@dbs.com", tag: "work")
      expect(json.dig(:data, :outcome)).to eq("added")
      expect(values).to match_array([ %w[mobile personal +6591882045], %w[email personal rachel@gmail.com], %w[email work rachel@google.com], %w[email work rachel@dbs.com] ])
    end

    it "answers the code step with what to verify" do
      post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "Rachel@Google.com", tag: "work" }, headers: app_as(token), as: :json
      expect(json[:data]).to eq(kind: "email", value: "rachel@google.com", display: "rachel@google.com", tag: "work", replace: false)
    end

    it "never takes a personal mail provider as a work email" do
      app_add_identity(token, kind: "email", value: "rachel@gmail.com", tag: "work")
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to start_with("Gmail, Outlook and other personal providers can't be a work email")
      expect(values).to eq([ %w[mobile personal +6591882045] ])
    end

    it "takes one work email per domain" do
      app_add_identity(token, kind: "email", value: "rachel@google.com", tag: "work")
      app_add_identity(token, kind: "email", value: "rachel.tan@google.com", tag: "work")
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("You already have a work email at google.com")
    end

    it "takes one personal email and one mobile, unless it is a change" do
      app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      app_add_identity(token, kind: "email", value: "rachel@outlook.com")
      expect(json.dig(:error, :message)).to eq("Only one personal email. Use Change Personal Email")
      app_add_identity(token, kind: "mobile", value: "9177 3301")
      expect(json.dig(:error, :message)).to eq("Only one mobile number. Use Change Mobile")
      app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      expect(json.dig(:error, :message)).to eq("Already on your account")
    end

    it "treats a mobile as personal whatever tag was sent and checks the format" do
      app_add_identity(token, kind: "mobile", value: "9177 3301", tag: "work", replace: true)
      expect(json.dig(:data, :identity)).to include(tag: "personal", value: "+6591773301")
      app_add_identity(token, kind: "mobile", value: "6123 4567", replace: true)
      expect(json.dig(:error, :message)).to eq("Enter an 8-digit Singapore mobile number")
      app_add_identity(token, kind: "email", value: "nope", tag: "personal")
      expect(json.dig(:error, :message)).to eq("Enter a valid email address")
      app_add_identity(token, kind: "email", value: "x@y.com", tag: "boss")
      expect(json.dig(:error, :details)).to eq(tag: [ "is not valid" ])
    end

    it "needs the right code, and a code for this value" do
      post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com", code: "123456" }, headers: app_as(token), as: :json
      expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")
      post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com" }, headers: app_as(token), as: :json
      post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com", code: "654321" }, headers: app_as(token), as: :json
      expect(json.dig(:error, :message)).to eq("That code is not right. Try again")
      post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "other@gmail.com", code: "123456" }, headers: app_as(token), as: :json
      expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")
      expect(values).to eq([ %w[mobile personal +6591882045] ])
    end

    it "works without a finished Create Your Account (the screens are reachable first)" do
      fresh = app_token(email: "new@google.com")
      get api_v1_convoy_app_identities_path, headers: app_as(fresh)
      expect(response).to have_http_status(:ok)
      app_add_identity(fresh, kind: "mobile", value: "9177 3301")
      expect(json.dig(:data, :outcome)).to eq("added")
    end

    it "keeps a code from working twice" do
      app_add_identity(token, kind: "email", value: "rachel@google.com", tag: "work")
      post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@google.com", tag: "work", code: "123456" },
                                                     headers: app_as(token), as: :json
      expect(json.dig(:error, :message)).to eq("That code has expired. Send a new one")
    end
  end

  describe "change" do
    it "replaces the personal email" do
      app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      app_add_identity(token, kind: "email", value: "rachel@outlook.com", replace: true)
      expect(json.dig(:data, :outcome)).to eq("changed")
      expect(values).to match_array([ %w[mobile personal +6591882045], %w[email personal rachel@outlook.com] ])
    end

    it "changes the mobile when it is the only identity: still one identity, no empty moment" do
      app_add_identity(token, kind: "mobile", value: "9177 3301", replace: true)
      expect(json[:data]).to include(outcome: "changed")
      expect(json.dig(:data, :identities).map { it[:value] }).to eq([ "+6591773301" ])
      expect(values).to eq([ %w[mobile personal +6591773301] ])
      expect(AppIdentityMove.count).to eq(0)
      expect(app_token(mobile: "9177 3301")).to be_present
      expect(json.dig(:data, :account, :id)).to eq(account.id)
    end
  end

  describe "a mobile of another account" do
    let!(:david) { create(:app_account, first_name: "David", mobile: "+6591773301", email: "david@gmail.com") }

    it "moves to whoever verifies it, records the move and tells the old owner by email" do
      expect { app_add_identity(token, kind: "mobile", value: "9177 3301", replace: true) }
        .to have_enqueued_mail(AppMailer, :identity_moved).with("david@gmail.com", "+65 9177 3301")
      expect(json[:data]).to include(outcome: "moved", identity: hash_including(value: "+6591773301"))
      expect(values).to eq([ %w[mobile personal +6591773301] ])
      expect(david.reload.identities.map(&:value)).to eq([ "david@gmail.com" ])
      expect(AppIdentityMove.last).to have_attributes(kind: "mobile", value: "+6591773301", from_app_account_id: david.id, to_app_account_id: account.id,
                                                      moved_at: be_present)
    end

    it "leaves the old account with no identity when it was its only one: it stays signed in and is told to add one" do
      only = create(:app_account, first_name: "Only", mobile: "+6598765432")
      only_token = app_token(mobile: "9876 5432")
      app_add_identity(token, kind: "mobile", value: "9876 5432", replace: true)
      expect(json.dig(:data, :outcome)).to eq("moved")
      expect(only.reload.identities).to be_empty

      get api_v1_convoy_app_session_path, headers: app_as(only_token)
      expect(response).to have_http_status(:ok)
      expect(json.dig(:data, :account)).to include(needs_identity: true, identities: [])
      get api_v1_convoy_app_profile_path, headers: app_as(only_token)
      expect(json.dig(:data, :needs_identity)).to be(true)
      app_add_identity(only_token, kind: "email", value: "only@gmail.com")
      expect(json.dig(:data, :outcome)).to eq("added")
      get api_v1_convoy_app_profile_path, headers: app_as(only_token)
      expect(json.dig(:data, :needs_identity)).to be(false)
    end

    it "signs the new owner in, not the old one, from then on" do
      app_add_identity(token, kind: "mobile", value: "9177 3301", replace: true)
      app_token(mobile: "9177 3301")
      expect(json.dig(:data, :account, :id)).to eq(account.id)
    end
  end

  it "refuses an email that belongs to another account (accounts are never joined)" do
    create(:app_account, first_name: "Other", email: "shared@gmail.com")
    app_add_identity(token, kind: "email", value: "Shared@gmail.com")
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("This email is on another Convoy account. Sign in with it there")
    expect(values).to eq([ %w[mobile personal +6591882045] ])

    create(:app_account, first_name: "Boss", email: "boss@google.com")
    app_add_identity(token, kind: "email", value: "boss@google.com", tag: "work")
    expect(json.dig(:error, :message)).to eq("This email is on another Convoy account. Sign in with it there")
    expect(AppIdentityMove.count).to eq(0)
  end

  describe "re-verify a work email" do
    let!(:work) { create(:app_identity, :work, app_account: account, value: "rachel@google.com", verified_at: Time.current) }

    def state = AppIdentity.find(work.id).reverify_state

    it "is ok, due_soon 30 days before the 12-month mark, then paused" do
      get api_v1_convoy_app_identities_path, headers: app_as(token)
      row = json[:data].find { it[:id] == work.id }
      expect(row).to include(reverify_state: "ok", reverify_due_on: 12.months.from_now.to_date.iso8601)

      work.update!(verified_at: 12.months.ago + 29.days)
      expect(state).to eq("due_soon")
      get api_v1_convoy_app_identities_path, headers: app_as(token)
      expect(json[:data].find { it[:id] == work.id }[:reverify_state]).to eq("due_soon")

      work.update!(verified_at: 12.months.ago + 31.days)
      expect(state).to eq("ok")
      work.update!(verified_at: 12.months.ago - 1.day)
      get api_v1_convoy_app_identities_path, headers: app_as(token)
      expect(json[:data].find { it[:id] == work.id }[:reverify_state]).to eq("paused")
    end

    it "verifying again renews it without adding a row" do
      work.update!(verified_at: 13.months.ago)
      app_add_identity(token, kind: "email", value: "Rachel@Google.com", tag: "work")
      expect(response).to have_http_status(:ok), json.inspect
      expect(json[:data]).to include(outcome: "reverified", identity: hash_including(id: work.id, reverify_state: "ok"))
      expect(account.identities.count).to eq(2)
      expect(state).to eq("ok")
    end
  end

  describe "remove" do
    it "refuses the only identity, and one in use" do
      delete api_v1_convoy_app_identity_path(account.identities.first), headers: app_as(token)
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Used to sign in. Add another first, then switch")

      app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      mobile = account.identities.find_by(kind: "mobile")
      allow(ConvoyApp::Identities::Uses).to receive(:call).and_wrap_original do |m, **args|
        m.call(**args).merge(mobile.id => [ "Tan Family" ])
      end
      delete api_v1_convoy_app_identity_path(mobile), headers: app_as(token)
      expect(json.dig(:error, :message)).to eq("Used by Tan Family. Add another first, then switch")
      expect(account.identities.count).to eq(2)
    end

    it "removes one of several and answers the rest" do
      app_add_identity(token, kind: "email", value: "rachel@gmail.com")
      email = account.identities.find_by(kind: "email")
      delete api_v1_convoy_app_identity_path(email), headers: app_as(token)
      expect(response).to have_http_status(:ok)
      expect(json[:data].map { it[:value] }).to eq([ "+6591882045" ])
      expect(values).to eq([ %w[mobile personal +6591882045] ])
    end

    it "cannot reach another account's identity" do
      other = create(:app_identity, :email)
      delete api_v1_convoy_app_identity_path(other), headers: app_as(token)
      expect(response).to have_http_status(:not_found)
      expect(AppIdentity.exists?(other.id)).to be(true)
    end
  end

  describe "codes" do
    it "keeps a sign-in code for a value from cancelling a pending Add Mobile code (codes scoped by purpose and account)" do
      create(:app_account, first_name: "David", mobile: "+6591773301")
      post code_api_v1_convoy_app_identities_path, params: { kind: "mobile", value: "9177 3301", replace: true }, headers: app_as(token), as: :json
      # someone asks a sign-in code for the same mobile
      post code_api_v1_convoy_app_session_path, params: { mobile: "9177 3301" }, as: :json
      expect(AppSignInCode.where(target: "+6591773301", used_at: nil).pluck(:purpose)).to match_array(%w[verify sign_in])

      post verify_api_v1_convoy_app_identities_path, params: { kind: "mobile", value: "9177 3301", replace: true, code: "123456" },
                                                     headers: app_as(token), as: :json
      expect(response).to have_http_status(:ok), json.inspect
      expect(json.dig(:data, :outcome)).to eq("moved")
    end

    it "replaces an older code of the same account and purpose" do
      2.times { post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com" }, headers: app_as(token), as: :json }
      expect(AppSignInCode.where(target: "rachel@gmail.com", used_at: nil).count).to eq(1)
    end

    it "keeps another account's pending code apart" do
      _other, other_token = app_user(mobile: "9177 3301", name: %w[David Tan])
      post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "x@google.com", tag: "work" }, headers: app_as(other_token), as: :json
      post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "x@google.com", tag: "work" }, headers: app_as(token), as: :json
      expect(AppSignInCode.where(target: "x@google.com", used_at: nil).count).to eq(2)
      post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "x@google.com", tag: "work", code: "123456" }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:ok)
      post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "x@google.com", tag: "work", code: "123456" }, headers: app_as(other_token), as: :json
      expect(json.dig(:error, :message)).to eq("This email is on another Convoy account. Sign in with it there")
    end

    it "limits codes to 5 an hour per mobile or email, then allows again" do
      5.times { post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com" }, headers: app_as(token), as: :json }
      expect(response).to have_http_status(:ok)
      post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com" }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(json.dig(:error, :message)).to eq("Too many codes asked for. Try again in an hour")
      travel 61.minutes
      post code_api_v1_convoy_app_identities_path, params: { kind: "email", value: "rachel@gmail.com" }, headers: app_as(token), as: :json
      expect(response).to have_http_status(:ok)
    end
  end

  describe "AppIdentity values" do
    it "are stored normalised, so a seed typed '9188 2045' or 'Rachel@X.com' still signs in" do
      other = create(:app_account, first_name: "Seeded")
      mobile = AppIdentity.create!(app_account: other, kind: "mobile", tag: "personal", value: "9177 3301", verified_at: Time.current)
      email = AppIdentity.create!(app_account: other, kind: "email", tag: "personal", value: " Seeded@Gmail.COM ", verified_at: Time.current)
      expect(mobile.value).to eq("+6591773301")
      expect(email).to have_attributes(value: "seeded@gmail.com", domain: "gmail.com")
      app_token(mobile: "+65 9177 3301")
      expect(json.dig(:data, :account, :id)).to eq(other.id)
      app_token(email: "seeded@gmail.com")
      expect(json.dig(:data, :account, :id)).to eq(other.id)
    end

    it "keep a work email off personal providers and a mobile off other countries" do
      expect(build(:app_identity, :work, value: "x@gmail.com")).not_to be_valid
      expect(build(:app_identity, value: "+6561234567")).not_to be_valid
      expect(build(:app_identity, tag: "work")).not_to be_valid
    end
  end
end
