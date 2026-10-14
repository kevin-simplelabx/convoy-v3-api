module Api
  class OsrmController < ApplicationController
    OSRM_BASE = ENV.fetch("OSRM_URL", "https://router.project-osrm.org")
    CACHE_TTL  = 24.hours

    # GET /api/osrm/route/v1/driving/*
    # GET /api/osrm/table/v1/driving/*
    def proxy
      # Strip /api/osrm prefix and keep the raw path (with literal semicolons intact)
      osrm_path    = request.path.delete_prefix("/api/osrm")
      upstream_url = "#{OSRM_BASE}#{osrm_path}#{query_string}"

      body, status = Rails.cache.fetch(upstream_url, expires_in: CACHE_TTL) do
        # url_encoded: false tells Faraday not to re-encode the URL
        conn     = osrm_client
        response = conn.get(upstream_url)
        [ response.body, response.status ]
      end

      render json: body, status: status
    rescue Faraday::Error => e
      render json: { error: "Routing service unavailable: #{e.message}" }, status: :bad_gateway
    end

    private

    def query_string
      request.query_string.present? ? "?#{request.query_string}" : ""
    end

    def osrm_client
      @osrm_client ||= Faraday.new do |f|
        f.options.timeout      = 10
        f.options.open_timeout = 5
        # Prevent Faraday from re-encoding already-valid URL characters
        f.request :url_encoded
      end
    end
  end
end
