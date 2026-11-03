# School Bus › Live Ops: a school's buses for a session of a day (KPIs, what needs attention, a row per run with its line
# and bus position) and one run in detail (alert, crew, log, stops with their children). GPS points of a run: Live Map's
# `GET /live_map/runs/:id/track`.
module Api
  module V1
    class SchoolLiveController < BaseController
      # GET /schools/:school_id/live?date=&session=am|pm|asa&filter=all|road|late|done
      def index
        school = authorize find_school, :show?
        render json: { data: SchoolLive::Board.new(school, date, session: params[:session]).call(filter: params[:filter].presence || "all") }
      end

      # GET /schools/:school_id/live/runs/:id
      def run
        school = authorize find_school, :show?
        occ = TripOccurrence.joins(school_route: :plan).where(school_plans: { school_id: school.id }).find(params[:id])
        render json: { data: SchoolLive::Board.new(school, occ.date, session: occ.school_route.plan.session).route(occ.id) }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def date
        params[:date].present? ? Date.iso8601(params[:date]) : Date.current
      rescue Date::Error
        raise ApplicationService::Error, "Date must look like 2026-11-03"
      end
    end
  end
end
