# School Bus › Year Setup › Bus Sessions of an academic year: the list, a copy of another year's as a draft, and
# Save & Lock (Unlock: POST /academic_years/:id/unlock { section: "sessions" }).
module Api
  module V1
    class BusSessionsController < BaseController
      TIMES = %i[arrive_from arrive_to dismissal depart].freeze

      # GET /academic_years/:academic_year_id/sessions
      def index
        year = find_year
        authorize year.school, :show?
        render_list year.bus_sessions.includes(:variants), BusSessionBlueprint, meta: { locked: lock(year), calendar_locked: SchoolSetup.locked?(school: year.school, year:, section: :calendar) }
      end

      # GET /academic_years/:academic_year_id/sessions/copy?from_id= — another year's sessions as a draft (not saved).
      def copy
        year = find_year
        authorize year.school, :setup?
        from = year.school.academic_years.includes(bus_sessions: :variants).find(params.require(:from_id))
        render json: { data: BusSessions::Copy.call(from, year) }
      end

      # PUT /academic_years/:academic_year_id/sessions { sessions: [{ name, direction, cca, service, max_journey_minutes, days,
      #   arrive_from, arrive_to, dismissal, depart, notes, variants: [{ days, arrive_from, arrive_to, dismissal, depart }] }] }
      def update
        year = find_year
        authorize year.school, :setup?
        list = params.permit(sessions: [ :name, :direction, :cca, :service, :max_journey_minutes, :notes, *TIMES, { days: [] },
                                         { variants: [ *TIMES, { days: [] } ] } ]).to_h.deep_symbolize_keys[:sessions]
        BusSessions::Save.call(year, list, user: current_user)
        index
      end

      private

      def find_year = AcademicYear.where(school: policy_scope(School)).includes(:school).find(params[:academic_year_id])

      def lock(year)
        l = SchoolSetup.find(year.school, year, :sessions)
        l && { at: l.locked_at, by: l.locked_by&.name }
      end
    end
  end
end
