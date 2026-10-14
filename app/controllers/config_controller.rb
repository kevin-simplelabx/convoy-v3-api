class ConfigController < ApplicationController
  def show
    config = {
      osrmBase: "/api/osrm",
      solveApi: "/api/solve",
      api: "/api/v1",
      demoLogin: ENV["DEMO_LOGIN"] == "true" || Rails.env.development?,
      maxEffort: ENV.fetch("MAX_EFFORT", "high")
    }
    render plain: "window.CONVOY_CONFIG = #{config.to_json};", content_type: "application/javascript"
  end
end
