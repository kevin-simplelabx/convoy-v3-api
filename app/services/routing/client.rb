# HTTP client of the routing service (ROUTING_URL, header X-Routing-Secret = ROUTING_SECRET). Tests swap it for a fake
# (spec/support/fake_routing.rb). Raises Unavailable when the service cannot be reached or fails.
module Routing
  class Client
    Unavailable = Class.new(StandardError)

    class << self
      attr_writer :current

      def current = @current ||= new
    end

    def solve(input) = post("/solve", { input: }, timeout: 150)
    def retime(payload) = post("/retime", payload, timeout: 60)
    def diff(a, b) = post("/diff", { a:, b: }, timeout: 30)
    def meta = Rails.cache.fetch("routing/meta", expires_in: 1.hour) { get("/meta") }

    private

    def conn(timeout)
      Faraday.new(url: ENV.fetch("ROUTING_URL", "http://localhost:4000"), headers: { "X-Routing-Secret" => ENV.fetch("ROUTING_SECRET", "dev") }) do |f|
        f.options.timeout = timeout
        f.options.open_timeout = 5
      end
    end

    def post(path, body, timeout:)
      parse(conn(timeout).post(path, body.to_json, "Content-Type" => "application/json"))
    end

    def get(path) = parse(conn(10).get(path))

    def parse(res)
      body = JSON.parse(res.body)
      raise Unavailable, body["error"] || "Routing service answered #{res.status}" unless res.success?

      body
    rescue Faraday::Error, JSON::ParserError => e
      raise Unavailable, e.message
    end
  end
end
