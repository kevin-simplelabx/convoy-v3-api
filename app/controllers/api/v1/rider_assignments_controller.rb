# School Bus › Stop Assignment › assigned PUDO points: Set as assigned (by hand), Unassign, Move All Riders Here (a point
# takes the riders assigned to the other points of its stop), and Notify (parents told their assigned PUDO; recorded only).
module Api
  module V1
    class RiderAssignmentsController < BaseController
      # POST /schools/:school_id/rider_assignments { rids: [], stop_point_id }
      def create
        school = find_school
        authorize Stop, :update?
        point = point_for(school, params.require(:stop_point_id))
        rids = Array(params[:rids]).map(&:to_s)
        raise ApplicationService::Error, "Pick riders" if rids.empty?

        rids.each { |rid| upsert(school, rid, point) }
        render json: { data: { assigned: rids.size } }
      end

      # POST /schools/:school_id/rider_assignments/remove { rids: [] } — Unassign: the riders lose their PUDO.
      def remove
        school = find_school
        authorize Stop, :update?
        rids = Array(params[:rids]).map(&:to_s)
        raise ApplicationService::Error, "Pick riders" if rids.empty?

        n = school.rider_assignments.where(rid: rids).destroy_all.size
        raise ApplicationService::Error, "None of these riders have a PUDO" if n.zero?

        render json: { data: { removed: n } }
      end

      # POST /schools/:school_id/rider_assignments/move { stop_point_id }
      def move
        school = find_school
        authorize Stop, :update?
        point = point_for(school, params.require(:stop_point_id))
        rows = school.rider_assignments.where(stop_point_id: point.stop.points.where.not(id: point.id).select(:id))
        n = rows.count
        rows.update_all(stop_point_id: point.id, manual: true, updated_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
        render json: { data: { moved: n } }
      end

      # POST /schools/:school_id/rider_assignments/notify — "Assigned PUDO sent to N riders" (sending comes with the app).
      def notify
        school = find_school
        authorize Stop, :update?
        n = school.rider_assignments.where(notified_at: nil).update_all(notified_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
        render json: { data: { notified: n } }
      end

      private

      def find_school = policy_scope(School).find(params[:school_id])
      def point_for(school, id) = StopPoint.where(stop: Stop.kept.visible_to(school)).includes(stop: :points).find(id)

      def upsert(school, rid, point)
        raise ApplicationService::Error, "#{rid} is not a rider of this school" unless school.riders.exists?(rid:)

        row = school.rider_assignments.find_or_initialize_by(rid:)
        row.update!(stop_point: point, manual: true, notified_at: nil)
      end
    end
  end
end
