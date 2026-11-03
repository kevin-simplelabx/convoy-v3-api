# Convoy Driver app › the bell (Notifications): the driver's lines at the picked company for the last 30 days, newest
# first, with the unread count for the red dot. An Acknowledge notice stays unread until acknowledged.
module Api
  module V1
    module DriverApp
      class NotificationsController < BaseController
        KEEP = 30.days
        LIMIT = 100

        before_action :require_membership!

        # GET /driver/notifications → { data: [line], meta: { unread } }
        def index
          list = scope.where(created_at: KEEP.ago..).includes(:vehicle, :notice).order(created_at: :desc, id: :desc).limit(LIMIT).to_a
          recipients = DriverNoticeRecipient.where(driver_notice_id: list.filter_map(&:driver_notice_id), **DriverNotification.member_key(current_membership))
                                            .index_by(&:driver_notice_id)
          render json: { data: DriverNotificationBlueprint.render_as_hash(list, recipients:), meta: { unread: scope.unread.where(created_at: KEEP.ago..).count } }
        end

        # POST /driver/notifications/:id/read
        def read
          line = scope.find(params[:id])
          mark_read(scope.where(id: line.id))
          head :no_content
        end

        # POST /driver/notifications/read_all
        def read_all
          mark_read(scope.unread)
          head :no_content
        end

        private

        def scope = DriverNotification.for_member(current_membership)

        # Not the Acknowledge notices: those are read when acknowledged.
        def mark_read(lines)
          ack = DriverNotice.where(kind: "ack").select(:id)
          lines.where(read_at: nil).where("driver_notice_id IS NULL OR driver_notice_id NOT IN (?)", ack).update_all(read_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
        end
      end
    end
  end
end
