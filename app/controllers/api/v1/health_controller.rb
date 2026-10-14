module Api
  module V1
    class HealthController < ApplicationController
      def show
        render json: { ok: true, rails: Rails.version, ruby: RUBY_VERSION, env: Rails.env }
      end
    end
  end
end
