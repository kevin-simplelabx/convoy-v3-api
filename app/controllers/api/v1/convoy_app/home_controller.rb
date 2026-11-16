# Convoy App › Home (greeting, invitations, notice banners + dismiss, Up Next, tiles + badges, Get Started) and Activity.
module Api
  module V1
    module ConvoyApp
      class HomeController < BaseController
        # GET /app/home → { greeting, invitations: { family, organisations }, banners, up_next, tiles, get_started, badges: { alerts } }
        def show
          render json: { data: ::ConvoyApp::Home.call(account: current_account) }
        end

        # POST /app/home/banners/:id/dismiss (X on a notice banner) → { dismissed: true }. The alert stays in the inbox.
        def dismiss
          banner = current_account.notifications.find(params[:id])
          banner.update!(dismissed_at: Time.current) unless banner.dismissed_at
          render json: { data: { id: banner.id, dismissed: true } }
        end

        # GET /app/activity?service=school|shuttle|booking → { services, service, now, upcoming, past }
        def activity
          render json: { data: ::ConvoyApp::Activity.call(account: current_account, service: params[:service]) }
        end
      end
    end
  end
end
