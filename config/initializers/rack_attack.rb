# Request limits per IP (and per email on sign-in). A refused request gets 429 with Retry-After and the usual error body:
# { error: { code: "too_many_requests", message: "Too many tries. Try again in 42 seconds", details: { retry_after: 42 } } }.
class Rack::Attack
  PORTAL_SESSION = "/api/v1/portal/session".freeze
  DRIVER_SESSION = "/api/v1/driver/session".freeze

  # The email of a sign-in request (JSON or form body), so one person's account is limited from any IP.
  def self.sign_in_email(req)
    ActionDispatch::Request.new(req.env).request_parameters["email"].to_s.strip.downcase.presence
  rescue ActionDispatch::Http::Parameters::ParseError
    nil
  end

  # Staff sign-in: 10 per minute per IP, 5 per minute per email
  throttle("logins/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/api/v1/session" && req.post?
  end
  throttle("logins/email", limit: 5, period: 60) do |req|
    sign_in_email(req) if req.path == "/api/v1/session" && req.post?
  end

  # A body field of a sign-in request (JSON or form), normalised, so one person is limited from any IP.
  def self.sign_in_field(req, key)
    ActionDispatch::Request.new(req.env).request_parameters[key].to_s.gsub(/\s+/, "").downcase.presence
  rescue ActionDispatch::Http::Parameters::ParseError
    nil
  end

  # Driver app code step: 30 per minute per IP. Codes are also limited to 5 an hour per mobile.
  throttle("driver_code/ip", limit: 30, period: 60) do |req|
    req.ip if req.post? && req.path == "#{DRIVER_SESSION}/code"
  end

  # Driver app sign-in (mobile + code, email + password): 10 per minute per IP, 5 per minute per mobile or email
  throttle("driver_credentials/ip", limit: 10, period: 60) do |req|
    req.ip if req.post? && [ DRIVER_SESSION, "#{DRIVER_SESSION}/email" ].include?(req.path)
  end
  throttle("driver_credentials/person", limit: 5, period: 60) do |req|
    if req.post? && [ DRIVER_SESSION, "#{DRIVER_SESSION}/email" ].include?(req.path)
      sign_in_field(req, "phone") || sign_in_field(req, "email")
    end
  end

  # Client Portal email step (lookup, send a code): 30 per minute per IP. Codes are also limited to 5 an hour per account.
  throttle("portal_lookup/ip", limit: 30, period: 60) do |req|
    req.ip if req.post? && [ "#{PORTAL_SESSION}/lookup", "#{PORTAL_SESSION}/code" ].include?(req.path)
  end

  # Client Portal password, code check and set password: 10 per minute per IP, 5 per minute per email
  throttle("portal_credentials/ip", limit: 10, period: 60) do |req|
    req.ip if req.post? && [ PORTAL_SESSION, "#{PORTAL_SESSION}/verify", "/api/v1/portal/password" ].include?(req.path)
  end
  throttle("portal_credentials/email", limit: 5, period: 60) do |req|
    sign_in_email(req) if req.post? && [ PORTAL_SESSION, "#{PORTAL_SESSION}/verify" ].include?(req.path)
  end

  # Share Form answers from hired drivers (public): 10 per hour per IP
  throttle("share_forms/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path.start_with?("/api/v1/public/share_forms/")
  end

  # Throttle general API: 300 per minute per IP
  throttle("api/ip", limit: 300, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  self.throttled_responder = lambda do |req|
    data = req.env["rack.attack.match_data"] || {}
    period = data[:period].to_i
    wait = period.positive? ? period - (data[:epoch_time].to_i % period) : 60
    body = { error: { code: "too_many_requests", message: "Too many tries. Try again in #{wait} seconds", details: { retry_after: wait } } }
    [ 429, { "content-type" => "application/json", "retry-after" => wait.to_s }, [ body.to_json ] ]
  end
end
