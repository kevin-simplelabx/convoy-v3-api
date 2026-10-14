module Api
  module V1
    class SolveController < BaseController
      before_action :require_company!

      SOLVER_URL    = ENV.fetch("SOLVER_URL", "http://localhost:3001")
      SOLVE_PER_HOUR = ENV.fetch("SOLVE_PER_HOUR", "30").to_i

      def create
        cid       = current_company.id.to_s
        busy_key  = "solve_busy:#{cid}"
        log_key   = "solve_log:#{cid}"

        if Rails.cache.read(busy_key)
          return render json: { error: "A routing run is already in progress. Try again when it finishes." },
                        status: :too_many_requests
        end

        log = (Rails.cache.read(log_key) || []).select { |t| Time.now.to_i - t < 3600 }
        if log.size >= SOLVE_PER_HOUR
          return render json: { error: "Routing limit reached (#{SOLVE_PER_HOUR} runs per hour). Try again later." },
                        status: :too_many_requests
        end

        log << Time.now.to_i
        Rails.cache.write(busy_key, true, expires_in: 125.seconds)
        Rails.cache.write(log_key,  log,  expires_in: 1.hour)

        begin
          response = solver_client.post("#{SOLVER_URL}/api/solve", request.raw_post) do |req|
            req.headers["Content-Type"] = "application/json"
          end
          render json: response.body, status: response.status
        rescue Faraday::Error => e
          render json: { error: "Solver unavailable: #{e.message}" }, status: :bad_gateway
        ensure
          Rails.cache.delete(busy_key)
        end
      end

      private

      def solver_client
        @solver_client ||= Faraday.new do |f|
          f.options.timeout      = 130
          f.options.open_timeout = 5
        end
      end
    end
  end
end
