# Convoy App › Alerts tab: the inbox (one per account across Family, staff and bookings), mark one read (on tap), Mark All Read.
module Api
  module V1
    module ConvoyApp
      class AlertsController < BaseController
        # GET /app/alerts?filter=all|delays|notices&page= → { data: [alert], meta: { page, limit, count, pages, filter, unread } }
        def index
          render json: ::ConvoyApp::Alerts::Inbox.call(account: current_account, filter: params[:filter], page: params[:page])
        end

        # POST /app/alerts/:id/read → the alert (read)
        def read
          alert = current_account.notifications.find(params[:id])
          alert.update!(read_at: Time.current) unless alert.read_at
          render json: { data: ::ConvoyApp::Alerts::Inbox.json(alert), meta: { unread: current_account.notifications.unread.count } }
        end

        # POST /app/alerts/read_all → { updated, unread: 0 }
        def read_all
          now = Time.current
          updated = current_account.notifications.unread.update_all(read_at: now, updated_at: now)
          render json: { data: { updated:, unread: 0 } }
        end
      end
    end
  end
end
