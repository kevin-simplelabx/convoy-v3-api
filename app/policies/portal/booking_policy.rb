# Client Portal bookings. Everyone sees the bookings they made and the bookings an approval step asked them about;
# roles that see all (every role but Member) also see the bookings for the sites they cover (no site: organisation-wide
# roles only); Super Admins and Admins see every booking waiting for approval (they may step in). Booking roles make bookings and accept
# the transport company's changes on bookings they see.
module Portal
  class BookingPolicy < ApplicationPolicy
    def index? = true
    def show? = true
    def create? = user.can?(:book)
    def accept_changes? = user.can?(:book)

    class Scope < ApplicationPolicy::Scope
      def resolve
        mine = scope.where(client_id: user.client_id)
        own = mine.where(created_by_client_user_id: user.id).or(mine.where(id: asked))
        own = own.or(mine.where(id: BookingApproval.where(status: "wait").select(:booking_id))) if user.can?(:step_in)
        user.can?(:see_all) ? own.or(user.limit_to_sites(mine)) : own
      end

      private

      def asked
        BookingApproval.joins(steps: :step_people).where(booking_approval_step_people: { client_user_id: user.id }).select(:booking_id)
      end
    end
  end
end
