# School Bus › Stop Library › photo requests: the requests and their photos (sent from the Convoy App), Ask for Photos on
# a point, close a request, Accept / Reject a photo, and the automatic requests (drivers / parents).
module Api
  module V1
    class StopPhotoRequestsController < BaseController
      INCLUDES = [ :school_rider, :created_by, { submissions: [], stop_point: :stop } ].freeze

      # GET /stop_photo_requests?status=open|closed|all
      def index
        authorize Stop, :index?
        list = StopPhotoRequest.includes(*INCLUDES).order(created_at: :desc)
        list = list.where(status: params[:status].presence || "open") unless params[:status] == "all"
        company = current_company
        render json: { data: list.map { row(it) },
                       meta: { pending_photos: StopPhotoSubmission.where(status: "pending").count,
                               auto: { driver: company.stop_photo_auto_driver, parent: company.stop_photo_auto_parent } } }
      end

      # POST /stop_photo_requests { stop_point_id, audience: parents|driver|both|parent, school_rider_id, max_submissions }
      def create
        authorize Stop, :update?
        point = StopPoint.where(stop: Stop.kept).find(params.require(:stop_point_id))
        rider = params[:school_rider_id].present? ? SchoolRider.find(params[:school_rider_id]) : nil
        req = StopPhotos.ask(point, audience: params.require(:audience), rider:, max: params[:max_submissions] || 6, user: current_user)
        render json: { data: row(StopPhotoRequest.includes(*INCLUDES).find(req.id)) }, status: :created
      end

      # DELETE /stop_photo_requests/:id — close it.
      def destroy
        authorize Stop, :update?
        StopPhotoRequest.find(params[:id]).update!(status: "closed")
        head :no_content
      end

      # POST /stop_photo_requests/submissions/:id/accept (multipart photo = the edited image, optional; annotations JSON)
      def accept
        authorize Stop, :update?
        sub = StopPhotoSubmission.find(params[:id])
        notes = params[:annotations].present? ? JSON.parse(params[:annotations]) : nil
        point = StopPhotos.accept(sub, edited: params[:photo].presence, annotations: notes)
        render_data point, StopPointBlueprint
      rescue JSON::ParserError
        raise ApplicationService::Error, "annotations must be JSON"
      end

      # POST /stop_photo_requests/submissions/:id/reject
      def reject
        authorize Stop, :update?
        StopPhotos.reject(StopPhotoSubmission.find(params[:id]))
        head :no_content
      end

      # PUT /stop_photo_requests/auto { driver, parent }
      def auto
        authorize Stop, :update?
        cast = ->(v) { ActiveModel::Type::Boolean.new.cast(v) || false }
        n = StopPhotos.auto(current_company, driver: cast.(params[:driver]), parent: cast.(params[:parent]), user: current_user)
        render json: { data: { driver: current_company.stop_photo_auto_driver, parent: current_company.stop_photo_auto_parent, changed: n } }
      end

      private

      def row(r)
        p = r.stop_point
        { id: r.id, stop_id: p.stop_id, stop_point_id: p.id, pudo_code: p.pudo_code, stop_name: p.stop.name, audience: r.audience,
          parent_of: r.school_rider&.name, max_submissions: r.max_submissions, status: r.status, auto: r.auto, created_by: r.created_by&.name,
          created_at: r.created_at, live: r.live_count,
          submissions: r.submissions.map do |s|
            { id: s.id, by: s.submitted_by_name, role: s.role, status: s.status, submitted_at: s.submitted_at, street_view_url: s.street_view_url,
              annotations: s.annotations, photo: s.decorate.photo_info }
          end }
      end
    end
  end
end
