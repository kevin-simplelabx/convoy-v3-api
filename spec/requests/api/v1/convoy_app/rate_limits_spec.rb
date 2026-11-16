require "rails_helper"

# Rack::Attack on the Convoy App code steps (the test cache is a null store, so it is switched on here with a memory store).
RSpec.describe "Convoy App rate limits" do
  around do |ex|
    old = Rack::Attack.cache.store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    ex.run
  ensure
    Rack::Attack.cache.store = old
  end

  before { travel_to Time.zone.local(2026, 11, 3, 9, 0, 18) }

  def ask_code(mobile, ip: "10.0.0.1") = post(code_api_v1_convoy_app_session_path, params: { mobile: }, as: :json, headers: { "REMOTE_ADDR" => ip })

  def try_code(value, code: "000000", ip: "10.0.0.1", key: :mobile)
    post api_v1_convoy_app_session_path, params: { key => value, code: }, as: :json, headers: { "REMOTE_ADDR" => ip }
  end

  it "limits code requests to 30 a minute per IP, with the usual 429 body" do
    30.times { |i| ask_code("9100 #{format('%04d', i)}") }
    expect(response).to have_http_status(:ok)
    ask_code("9199 9999")
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to eq("42")
    expect(json[:error]).to eq(code: "too_many_requests", message: "Too many tries. Try again in 42 seconds", details: { retry_after: 42 })
    ask_code("9199 9999", ip: "10.0.0.2")
    expect(response).to have_http_status(:ok)
  end

  it "limits code checks to 5 a minute per mobile from any IP (spaces ignored)" do
    5.times { |i| try_code(i.even? ? "9188 2045" : "91 88 2045", ip: "10.0.1.#{i}") }
    expect(response).to have_http_status(:unprocessable_content)
    try_code("9188  2045", ip: "10.0.2.1")
    expect(response).to have_http_status(:too_many_requests)
    try_code("9177 3301", ip: "10.0.2.1")
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "limits code checks per email the same way" do
    5.times { |i| try_code("Rachel@Gmail.com", key: :email, ip: "10.0.1.#{i}") }
    try_code("rachel@gmail.com", key: :email, ip: "10.0.2.1")
    expect(response).to have_http_status(:too_many_requests)
  end

  it "limits code checks to 10 a minute per IP across mobiles, and Add Mobile verifies too" do
    10.times { |i| try_code("9100 #{format('%04d', i)}", ip: "10.0.3.1") }
    expect(response).to have_http_status(:unprocessable_content)
    try_code("9100 5555", ip: "10.0.3.1")
    expect(response).to have_http_status(:too_many_requests)

    token = app_token(mobile: "9188 2045")
    10.times { post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "a@gmail.com", code: "1" }, headers: app_as(token).merge("REMOTE_ADDR" => "10.0.4.1"), as: :json }
    post verify_api_v1_convoy_app_identities_path, params: { kind: "email", value: "a@gmail.com", code: "1" }, headers: app_as(token).merge("REMOTE_ADDR" => "10.0.4.1"), as: :json
    expect(response).to have_http_status(:too_many_requests)
  end

  it "stops a 6th code in an hour for one mobile even from other IPs" do
    5.times { |i| ask_code("9188 2045", ip: "10.0.5.#{i}") }
    ask_code("9188 2045", ip: "10.0.5.9")
    expect(response).to have_http_status(:unprocessable_content)
    expect(json.dig(:error, :message)).to eq("Too many codes asked for. Try again in an hour")
  end
end
