require "rails_helper"

# Rack::Attack limits (the test cache is a null store, so they are switched on here with a memory store): 429 with
# Retry-After and the usual error body; Portal lookups have their own, larger limit; sign-in is also limited per email.
RSpec.describe "Rate limits" do
  around do |ex|
    old = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    ex.run
  ensure
    Rack::Attack.cache.store = old
  end

  before { travel_to Time.zone.local(2026, 11, 3, 9, 0, 18) }

  def sign_in(email, ip: "10.0.0.1")
    post api_v1_portal_session_path, params: { email:, password: "Wrong123!" }, as: :json, headers: { "REMOTE_ADDR" => ip }
  end

  it "answers 429 with Retry-After and the usual error object" do
    5.times { sign_in("priya@google.com") }
    expect(response).to have_http_status(:unauthorized)
    sign_in("priya@google.com")
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("42")
    expect(json[:error]).to eq(code: "too_many_requests", message: "Too many tries. Try again in 42 seconds", details: { retry_after: 42 })
  end

  it "limits sign-in per email from any IP, and per IP across emails" do
    5.times { |i| sign_in("priya@google.com", ip: "10.0.1.#{i}") }
    sign_in("priya@google.com", ip: "10.0.2.1")
    expect(response).to have_http_status(:too_many_requests)

    10.times { |i| sign_in("user#{i}@google.com", ip: "10.0.3.1") }
    expect(response).to have_http_status(:unauthorized)
    sign_in("other@google.com", ip: "10.0.3.1")
    expect(response).to have_http_status(:too_many_requests)
  end

  it "keeps lookups apart from sign-in, so mistyped emails don't lock the password step" do
    12.times { post lookup_api_v1_portal_session_path, params: { email: "nobody@x.sg" }, as: :json }
    expect(response).to have_http_status(:unprocessable_content)
    sign_in("priya@google.com")
    expect(response).to have_http_status(:unauthorized)

    19.times { post lookup_api_v1_portal_session_path, params: { email: "nobody@x.sg" }, as: :json }
    expect(response).to have_http_status(:too_many_requests)
  end
end
