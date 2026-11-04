# Client Portal pages that only read: Home, Shuttles, Notices, Invoices (billing roles).
module Api
  module V1
    module Portal
      class PagesController < AppController
        # GET /portal/home
        def home
          authorize_portal :shell, :show?
          render json: { data: ::Portal::Home.call(client_user: current_client_user) }
        end

        # GET /portal/shuttles
        def shuttles
          authorize_portal :shell, :show?
          render json: { data: ::Portal::Shuttles.call(client_user: current_client_user) }
        end

        # GET /portal/notices
        def notices
          authorize_portal :shell, :show?
          render json: { data: ::Portal::Notices.call(client_user: current_client_user) }
        end

        # GET /portal/invoices?filter=all|not_paid|trips|school_bus&q=
        def invoices
          authorize_portal :settings, :billing?
          render json: { data: ::Portal::Invoices.call(client_user: current_client_user, filter: params[:filter], q: params[:q]) }
        end
      end
    end
  end
end
