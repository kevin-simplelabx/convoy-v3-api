# Trip Tracking page (public, no sign-in): the run a shared link shows, while it is open.
module Api
  module V1
    module Public
      class TrackingController < ApplicationController
        include ErrorHandling

        def show
          link = ActsAsTenant.without_tenant { TrackingLink.find_by!(token: params[:token]) }
          return render_error(:gone, "This tracking link has closed") unless link.open?

          s = link.snapshot
          now = Time.current
          state = if now < Time.zone.parse(s["starts_at"]) then "upcoming"
          elsif now < Time.zone.parse(s["ends_at"]) then "live"
          else "done"
          end
          render json: { data: s.merge("state" => state, "closes_at" => link.expires_at, "powered_by" => "CONVOY") }
        end
      end
    end
  end
end
