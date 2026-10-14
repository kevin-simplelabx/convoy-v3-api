class Rack::Attack
  # Throttle login attempts: 10 per minute per IP
  throttle("logins/ip", limit: 10, period: 60) do |req|
    req.ip if req.path == "/api/v1/login" && req.post?
  end

  # Throttle general API: 300 per minute per IP
  throttle("api/ip", limit: 300, period: 60) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  self.throttled_responder = lambda do |_req|
    [ 429, { "Content-Type" => "application/json" }, [ { error: "Too many requests" }.to_json ] ]
  end
end
