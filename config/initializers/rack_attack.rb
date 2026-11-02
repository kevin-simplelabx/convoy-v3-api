class Rack::Attack
  # Throttle login attempts: 10 per minute per IP
  throttle("logins/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/api/v1/session" && req.post?
  end

  # Share Form answers from hired drivers (public): 10 per hour per IP
  throttle("share_forms/ip", limit: 10, period: 1.hour) do |req|
    req.ip if req.post? && req.path.start_with?("/api/v1/public/share_forms/")
  end

  # Throttle general API: 300 per minute per IP
  throttle("api/ip", limit: 300, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  self.throttled_responder = lambda do |_req|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests" }.to_json ] ]
  end
end
