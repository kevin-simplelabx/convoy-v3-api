module Api
  module V1
    class LibraryController < BaseController
      before_action :require_company!
      before_action -> { require_read_permission!("library") }, only: [:requests]
      before_action -> { require_permission!("library") }, only: [:update_status]

      # GET /api/v1/library/requests
      def requests
        sl      = StopLibrary.for_company(current_company)
        pending = sl.lib.select { |s| s["libStatus"] == "pending" }

        school_names = School.where(id: pending.map { |s| s["ownerSchool"] }.compact.uniq)
                             .pluck(:id, :name).to_h

        result = pending.map do |s|
          {
            uid:    s["uid"],
            id:     s["id"],
            name:   s["name"],
            school: school_names[s["ownerSchool"].to_i] || "",
            by:     s["requestedBy"] || "",
            at:     s["requestedAt"] || ""
          }
        end
        render json: result
      end

      # POST /api/v1/library/:uid/status
      def update_status
        sl   = StopLibrary.for_company(current_company)
        stop = sl.lib.find { |s| s["uid"] == params[:uid] }
        return render_error("Stop not found", :not_found) unless stop

        valid_statuses = %w[approved school pending]
        return render_error("Bad status") unless valid_statuses.include?(params[:status])

        stop["libStatus"] = params[:status]
        sl.save!
        render json: { ok: true }
      end
    end
  end
end
