# School Bus › Stop Library › photo requests: the requests and their photos (sent from the Convoy App or recorded by the
# office), tabs Open / To Review / Closed, Ask for Photos on a point, Close / Reopen / Remove a request, Add Received
# Photos, Accept / Reject a photo, and the automatic requests (drivers / parents).
module Api
  module V1
    class StopPhotoRequestsController < BaseController
      INCLUDES = [ :school_rider, :created_by, { submissions: [], stop_point: :stop } ].freeze

      # GET /stop_photo_requests?status=open|review|closed|all — review = requests with photos to review.
      def index
        authorize Stop, :index?
        pending = StopPhotoSubmission.where(status: "pending").select(:stop_photo_request_id)
        list = StopPhotoRequest.includes(*INCLUDES).order(created_at: :desc)
        list = case params[:status].presence || "open"
        when "all" then list
        when "review" then list.where(id: pending)
        else list.where(status: params[:status] == "closed" ? "closed" : "open")
        end
        company = current_company
        counts = { open: StopPhotoRequest.open.count, review: StopPhotoRequest.where(id: pending).count, closed: StopPhotoRequest.where(status: "closed").count }
        render json: { data: list.map { row(it) },
                       meta: { counts:, pending_photos: StopPhotoSubmission.where(status: "pending").count,
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

      # POST /stop_photo_requests/:id/close
      def close
        authorize Stop, :update?
        StopPhotos.close(find)
        render_request
      end

      # POST /stop_photo_requests/:id/reopen
      def reopen
        authorize Stop, :update?
        StopPhotos.reopen(find)
        render_request
      end

      # DELETE /stop_photo_requests/:id — Remove: the request and its photos go (a photo already accepted stays the point's).
      def destroy
        authorize Stop, :update?
        find.destroy!
        head :no_content
      end

      # POST /stop_photo_requests/:id/submissions (multipart photos[] up to 3, submitted_by_name, role: parent|driver, street_view_url)
      def receive
        authorize Stop, :update?
        out = StopPhotos.receive(find, photos: params[:photos], by: params[:submitted_by_name], role: params[:role], street_view_url: params[:street_view_url],
                                       user: current_user)
        render_request(meta: out, status: :created)
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

      def find = StopPhotoRequest.find(params[:id])

      def render_request(meta: nil, status: :ok)
        body = { data: row(StopPhotoRequest.includes(*INCLUDES).find(params[:id])) }
        body[:meta] = meta if meta
        render json: body, status:
      end

      def row(r)
        p = r.stop_point
        { id: r.id, stop_id: p.stop_id, stop_point_id: p.id, pudo_code: p.pudo_code, stop_name: p.stop.name, audience: r.audience,
          parent_of: r.school_rider&.name, max_submissions: r.max_submissions, status: r.status, auto: r.auto, created_by: r.created_by&.name,
          created_at: r.created_at, live: r.live_count,
          submissions: r.submissions.map do |s|
            { id: s.id, by: s.submitted_by_name, role: s.role, status: s.status, submitted_at: s.submitted_at, street_view_url: s.street_view_url,
              source: s.source, n: s.batch_index, of: s.batch_size,
              annotations: s.annotations, photo: s.decorate.photo_info }
          end }
      end
    end
  end
end
