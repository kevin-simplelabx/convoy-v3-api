# Dashboard (Company Dashboard): the widgets this user may see, their layout (saved per user, Reset to the default) and
# the figures of each widget for a period.
module Api
  module V1
    class DashboardController < BaseController
      skip_after_action :verify_authorized

      # GET /dashboard?period=today|d7|d30|month|last_month&widgets[]=otp — the figures of the widgets (all the user may see).
      def show
        render json: { data: Dashboard::Widgets.new(user: current_user, period: params[:period]).call(params[:widgets]) }
      end

      # GET /dashboard/widgets — sections and widgets (default sizes) the user may see.
      def widgets
        render json: { data: { sections: Dashboard::Catalogue::SECTIONS, widgets: Dashboard::Catalogue.for(current_user),
                               cols: Dashboard::Catalogue::COLS, max_pages: Dashboard::Catalogue::MAX_PAGES } }
      end

      # GET /dashboard/layout — the user's layout (the default one until they save).
      def layout
        render_layout
      end

      # PUT /dashboard/layout { pages: [{ name, items: [{ widget, x, y, cols, rows }] }] }
      def save_layout
        raise ApplicationService::Error, "View only. Convoy Admin cannot change company data" if current_user.convoy_admin?

        pages = Array(params.require(:pages)).map { |p| p.permit(:name, items: %i[widget x y cols rows]).to_h }
        pages.each do |p|
          p["items"] = Array(p["items"]).select { |it| Dashboard::Catalogue::WIDGETS.key?(it["widget"]) && Dashboard::Catalogue.allowed?(current_user, it["widget"]) }
                                        .map { |it| it.merge(%w[x y cols rows].to_h { |k| [ k, it[k].to_i ] }) }
        end
        record.update!(pages:)
        render_layout
      end

      # DELETE /dashboard/layout — Reset to the default layout.
      def reset_layout
        DashboardLayout.where(user: current_user).delete_all
        render_layout
      end

      private

      def record = DashboardLayout.find_or_initialize_by(user: current_user)

      def render_layout
        saved = DashboardLayout.find_by(user: current_user)
        render json: { data: { pages: saved&.pages || Dashboard::Catalogue.default_layout(current_user), saved: saved.present?, updated_at: saved&.updated_at } }
      end
    end
  end
end
