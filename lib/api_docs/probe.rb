# Development only: GETs every endpoint against the seed data, signed in as the seed Admin, so lists and records get
# realistic examples (tmp/openapi/probe.json). Read-only; path ids are the first matching seed rows.
module ApiDocs
  class Probe
    EMAIL = "ops@simpledrive.sg"
    PASSWORD = "Simple123!"
    MODELS = { "api/v1/occurrences" => "TripOccurrence", "stop_id" => "TripStop", "api/v1/trip_history" => "TripOccurrence",
               "api/v1/live_map" => "Vehicle", "api/v1/routing" => "RoutingRun", "api/v1/route_money" => "RouteCharge",
               "api/v1/cca_rides" => "CcaRideSetting" }.freeze

    def self.call = new.call

    def call
      raise "Run in development (seed data)" unless Rails.env.development?

      sign_in
      company = User.find_by!(email: EMAIL).company
      recorder = Recorder.new
      routes.each do |route|
        path = ActsAsTenant.with_tenant(company) { fill(route) } or next
        session.get(path, headers: { "Authorization" => "Bearer #{@token}" })
        recorder.record(session.request, session.response) if session.response.successful?
      end
      recorder.write(Recorder::PROBE)
    end

    private

    def session
      @session ||= ActionDispatch::Integration::Session.new(Rails.application).tap { it.host! "localhost" }
    end

    def sign_in
      session.post "/api/v1/session", params: { email: EMAIL, password: PASSWORD }, as: :json
      raise "Sign in failed: #{session.response.body}" unless session.response.successful?

      @token = JSON.parse(session.response.body).dig("data", "token")
    end

    def routes
      Rails.application.routes.routes.filter_map do |r|
        path = r.path.spec.to_s.delete_suffix("(.:format)")
        { path:, controller: r.defaults[:controller] } if r.verb == "GET" && path.start_with?("/api/v1/")
      end.uniq
    end

    # /vehicles/:vehicle_id/log_cards/:id → /vehicles/12/log_cards/3 (each id within the ids picked before it).
    def fill(route)
      picked = {}
      route[:path].scan(/:(\w+)/).flatten.each do |name|
        klass = model_for(name, route[:controller]) or return
        scope = klass.all
        picked.each { |column, id| scope = scope.where(column => id) if klass.column_names.include?(column) }
        scope = scope.where(date: Date.current) if klass.column_names.include?("date") && scope.where(date: Date.current).exists?
        picked[name == "id" ? "id" : name] = scope.first&.id or return
      end
      picked.reduce(route[:path]) { |path, (name, id)| path.sub(":#{name}", id.to_s) }
    end

    def model_for(name, controller)
      key = name == "id" ? controller : name
      (MODELS[key] || key.delete_prefix("api/v1/").delete_suffix("_id").split("/").last.classify).safe_constantize
    end
  end
end
