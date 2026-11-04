# Client Portal › Approvals: bookings waiting for the viewer's decision (Waiting for You), then the other bookings waiting
# for approval that the viewer may see (Waiting for Others: Super Admins and Admins every one, others their sites').
module Api
  module V1
    module Portal
      class ApprovalsController < AppController
        # GET /portal/approvals
        def index
          authorize_portal Booking, :index?
          waiting = policy_scope([ :portal, Booking ]).where(id: BookingApproval.where(status: "wait").select(:booking_id))
                                                      .includes(*BookingsController::LIST_INCLUDES).order(created_at: :desc).to_a
          mine, others = waiting.partition { ::Portal::Approval.new(it.approval).can_decide?(current_client_user) }
          others.select! { current_client_user.can?(:step_in) || current_client_user.covers?(it.client_site_id) }
          options = { viewer: current_client_user, buses: {} }
          render json: { data: { waiting_for_you: PortalBookingBlueprint.render_as_hash(mine, **options),
                                 waiting_for_others: PortalBookingBlueprint.render_as_hash(others, **options) } }
        end
      end
    end
  end
end
