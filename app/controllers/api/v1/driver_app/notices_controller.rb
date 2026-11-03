# Convoy Driver app › a notice from the office: the detail page (opening it reads it) and Acknowledge (recorded with the
# time; the office sees who acknowledged).
module Api
  module V1
    module DriverApp
      class NoticesController < BaseController
        before_action :require_membership!

        # GET /driver/notices/:id
        def show
          recipient.update!(read_at: recipient.read_at || Time.current)
          lines.where(read_at: nil).update_all(read_at: Time.current) if notice.view? # rubocop:disable Rails/SkipsModelValidations
          render_notice
        end

        # POST /driver/notices/:id/acknowledge
        def acknowledge
          raise ApplicationService::Error, "This notice needs no acknowledgement" unless notice.ack?

          now = Time.current
          recipient.update!(read_at: recipient.read_at || now, acknowledged_at: recipient.acknowledged_at || now)
          lines.where(read_at: nil).update_all(read_at: now) # rubocop:disable Rails/SkipsModelValidations
          render_notice
        end

        private

        def key = DriverNotification.member_key(current_membership)
        def recipient = @recipient ||= DriverNoticeRecipient.find_by!(driver_notice_id: params[:id], **key)
        def notice = @notice ||= recipient.notice
        def lines = DriverNotification.where(driver_notice_id: notice.id, **key)

        def render_notice = render json: { data: DriverNoticeBlueprint.render_as_hash(notice.decorate, recipient:) }
      end
    end
  end
end
