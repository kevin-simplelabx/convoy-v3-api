# Delete Family (Admin only): the Family, its children, pending invites and requests go for every adult; their own accounts,
# shuttles and bookings stay, and what a school or company must keep stays with them. Refused while a child has a bus
# service, an accepted request or an unpaid bill (BusService.delete_blockers).
module ConvoyApp
  module Households
    class Delete < ApplicationService
      def initialize(household:)
        @household = household
      end

      def call
        @household.with_lock do
          blockers = BusService.delete_blockers(@household)
          if blockers.any?
            raise Error.new("This Family can't be deleted yet. Stop the service with the transport company and settle invoices first.",
                            code: "family_blocked", details: { reasons: blockers })
          end

          @household.dependants.each(&:discard!)
          @household.members.delete_all
          @household.invite_links.delete_all
          @household.discard!
        end
      end
    end
  end
end
