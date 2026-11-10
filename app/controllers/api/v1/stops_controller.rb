# School Bus › Stop Library: the company's stops (as a school sees them when school_id is given: approved stops and its
# own; without it, the whole library), one stop, add / change
# (with the confirmation for stops other schools use), archive, Nearby in Library, the requests to add stops and their
# answers, and a point's photo.
module Api
  module V1
    class StopsController < BaseController
      INCLUDES = [ :owner_school, :requested_by, { points: [], school_stops: :school } ].freeze
      NEARBY_M = 600

      # GET /stops?school_id=&q=&status=&not_linked=1
      def index
        authorize Stop
        school = context_school
        list = visible(Stop.kept).includes(*INCLUDES).order(:code)
        list = list.search(params[:q]) if params[:q].present?
        list = list.where(library_status: params[:status]) if Stop::STATUSES.include?(params[:status])
        list = list.where.not(id: SchoolStop.where(school:).select(:stop_id)) if school && params[:not_linked].present?
        render_page list, StopBlueprint, school_id: school&.id, subzones:
      end

      def show
        stop = authorize find
        render_data stop, StopBlueprint, view: :detail, school_id: context_school&.id, subzones:
      end

      # POST /stops { stop: { name, points: [{ description, usage, sizes, primary, lat, lng, street_view_url }] }, school_id, in_library }
      def create
        authorize Stop
        stop = Stops::Save.call(stop_params, user: current_user, school: context_school, in_library: params[:in_library].to_s != "false")
        render_data find(stop.id), StopBlueprint, view: :detail, school_id: context_school&.id, subzones:, status: :created
      end

      # PATCH /stops/:id { stop: { name, points: [{ id, … }] }, school_id, confirmed }
      def update
        stop = authorize find
        Stops::Save.call(stop_params, user: current_user, stop:, school: context_school, confirmed: params[:confirmed].to_s == "true")
        render_data find(stop.id), StopBlueprint, view: :detail, school_id: context_school&.id, subzones:
      end

      # DELETE /stops/:id — Archive (only when no school uses it); riders still assigned to its points are unassigned.
      def destroy
        stop = authorize find
        render json: { data: { unassigned: Stops::Archive.call(stop) } }
      end

      # GET /stops/nearby?lat=&lng=&school_id= — library stops within 600 m that the school does not use yet.
      def nearby
        authorize Stop, :index?
        school = context_school
        lat = params.require(:lat).to_f
        lng = params.require(:lng).to_f
        pad = 0.007
        list = visible(Stop.kept).includes(*INCLUDES)
                   .where(id: StopPoint.where(retired_at: nil, lat: (lat - pad)..(lat + pad), lng: (lng - pad)..(lng + pad)).select(:stop_id))
        list = list.where.not(id: SchoolStop.where(school:).select(:stop_id)) if school
        near = list.to_a.filter_map do |s|
          m = s.points.map { Geo.metres([ lat, lng ], [ it.lat, it.lng ]) }.min
          [ s, m.round ] if m && m <= NEARBY_M
        end
        render json: { data: near.sort_by(&:last).map { |s, m| StopBlueprint.render_as_hash(s, school_id: school&.id, subzones:).merge(metres: m) } }
      end

      # GET /stops/requests — stops waiting to join the library.
      def requests
        authorize Stop, :review?
        render_list Stop.kept.where(library_status: "pending").includes(*INCLUDES).order(:requested_at), StopBlueprint, subzones:
      end

      # POST /stops/:id/library — Add to the Stop Library (approved with the library permission, else pending).
      def ask_library
        stop = authorize find, :update?
        render_data Stops::Library.ask(stop, current_user), StopBlueprint, subzones:
      end

      # POST /stops/:id/review { status: approved | school }
      def review
        stop = authorize find, :review?
        render_data Stops::Library.review(stop, params.require(:status)), StopBlueprint, subzones:
      end

      # POST /stops/:id/points/:point_id/photo (multipart photo, photo_original; photo_annotations JSON; photo_credit)
      def photo
        stop = authorize find, :update?
        point = stop.points.find(params[:point_id])
        if request.delete?
          point.remove_photo!
          point.remove_photo_original!
          point.update!(photo_annotations: nil, photo_credit: nil)
        else
          point.photo = params.require(:photo)
          point.photo_original = params[:photo_original] if params[:photo_original].present?
          point.photo_annotations = JSON.parse(params[:photo_annotations]) if params[:photo_annotations].present?
          point.photo_credit = params[:photo_credit].presence
          point.save!
        end
        render_data point, StopPointBlueprint
      rescue JSON::ParserError
        raise ApplicationService::Error, "photo_annotations must be JSON"
      end

      private

      def find(id = params[:id]) = visible(Stop.with_discarded).includes(*INCLUDES).find(id)

      # As a school sees the library (approved stops and its own); without a school, the whole company's library.
      def visible(scope) = context_school ? scope.visible_to(context_school) : scope

      def context_school
        return @context_school if defined?(@context_school)

        @context_school = params[:school_id].present? ? policy_scope(School).find(params[:school_id]) : nil
      end

      def subzones = @subzones ||= UraSubzone.pluck(:code, :name, :planning_area).to_h { |c, n, a| [ c, { code: c, name: n, planning_area: a } ] }

      def stop_params
        params.require(:stop).permit(:name, points: [ :id, :description, :usage, :primary, :lat, :lng, :street_view_url, { sizes: [] } ])
              .to_h.deep_symbolize_keys.tap { |p| p[:points] = Array(p[:points]).map { |x| x.merge(primary: ActiveModel::Type::Boolean.new.cast(x[:primary])) } }
      end
    end
  end
end
