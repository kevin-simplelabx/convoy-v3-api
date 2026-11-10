# School Bus › Stop Assignment of a school: its stops with their catchments (postal codes, areas, points off) and
# riders, Add to School / change the catchment, Unlink, Import from Another School, the riders' PUDO points on a date,
# and the hand links (Select Riders / Select Links).
module Api
  module V1
    class SchoolStopsController < BaseController
      # GET /schools/:school_id/stops?attention=1
      def index
        school = find_school
        authorize Stop, :index?
        all = school.school_stops.includes(stop: [ :owner_school, :requested_by, { points: [], school_stops: :school } ]).select { it.stop.kept? }
          .sort_by { it.stop.code }
        riders = SchoolRider.of_school_on(school, Date.current).to_a
        rows = all.map { row(it, riders) }
        shown = params[:attention].present? ? rows.select { it[:stop][:needs_attention] } : rows
        render json: { data: shown, meta: { counts: { school_stops: rows.size, needs_attention: rows.count { it[:stop][:needs_attention] } },
                                            stops_changed_at: school.stops_changed_at } }
      end

      # PUT /schools/:school_id/stops/:id { postal_codes: [] | "460101, …", areas: [{ name, latlngs, exclude, how }], off_point_ids: [] }
      def update
        school = find_school
        authorize Stop, :update?
        stop = Stop.kept.visible_to(school).includes(:points).find(params[:id])
        ss, invalid, shared = SchoolStops::Save.call(school, stop, catchment_params)
        render json: { data: row(ss, SchoolRider.of_school_on(school, Date.current).to_a), meta: { invalid:, shared: } }
      end

      # DELETE /schools/:school_id/stops/:id — Unlink (the school's hand links and rider assignments at its points go too).
      def destroy
        school = find_school
        authorize Stop, :update?
        stop = Stop.with_discarded.find(params[:id])
        render json: { data: { unassigned: SchoolStops::Unlink.call(school, stop) } }
      end

      # POST /schools/:school_id/stops/import { from_school_id, with_catchments }
      def import
        school = find_school
        authorize Stop, :update?
        from = policy_scope(School).find(params.require(:from_school_id))
        copy = ActiveModel::Type::Boolean.new.cast(params[:with_catchments])
        have = school.school_stops.pluck(:stop_id)
        added = from.school_stops.joins(:stop).merge(Stop.kept.visible_to(school)).where.not(stop_id: have).map do |o|
          SchoolStop.create!(school:, stop_id: o.stop_id, postal_codes: copy ? o.postal_codes : [], areas: copy ? o.areas : [])
        end
        render json: { data: { added: added.size } }
      end

      # GET /schools/:school_id/stop_assignment?date=
      def assignment
        school = find_school
        authorize Stop, :index?
        date = params[:date].present? ? Date.iso8601(params[:date]) : Date.current
        a = SchoolStops::Assignment.new(school, date:)
        render json: { data: a.riders, meta: { date:, counts: a.counts, stops_changed_at: school.stops_changed_at } }
      rescue Date::Error
        raise ApplicationService::Error, "Date must look like 2026-11-02"
      end

      # POST /schools/:school_id/rider_links { stop_point_id, rids: [], postals: [] } — Select Riders › link as an alternative.
      def link
        school = find_school
        authorize Stop, :update?
        point = StopPoint.where(stop: Stop.kept.visible_to(school)).find(params.require(:stop_point_id))
        SchoolStops::Links.link(school, point, rids: Array(params[:rids]).map(&:to_s), postals: Array(params[:postals]).map(&:to_s), user: current_user)
        head :no_content
      end

      # POST /schools/:school_id/rider_links/remove { links: [{ rid, point_id }] } — Select Links › Remove; riders assigned to
      # a removed point are unassigned.
      def unlink
        school = find_school
        authorize Stop, :update?
        links = params.permit(links: %i[rid point_id]).to_h.deep_symbolize_keys[:links]
        raise ApplicationService::Error, "Pick the links to remove" if links.blank?

        render json: { data: { unassigned: SchoolStops::Links.remove(school, links, user: current_user) } }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])

      def subzones = @subzones ||= UraSubzone.pluck(:code, :name, :planning_area).to_h { |c, n, a| [ c, { code: c, name: n, planning_area: a } ] }

      def catchment_params
        p = params.permit(:postal_codes, postal_codes: [], off_point_ids: [], areas: [ :name, :exclude, :how, { latlngs: [] } ]).to_h.deep_symbolize_keys
        p[:areas] = Array(params[:areas]).map { |a| a.permit(:name, :exclude, :how).to_h.symbolize_keys.merge(latlngs: a[:latlngs]) } if params.key?(:areas)
        p
      end

      def row(ss, riders)
        { stop: StopBlueprint.render_as_hash(ss.stop, school_id: ss.school_id, subzones:), postal_codes: ss.postal_codes, areas: ss.areas,
          off_point_ids: ss.off_point_ids, riders: riders.count { ss.covers?(it.postal, it.lat, it.lng) } }
      end
    end
  end
end
