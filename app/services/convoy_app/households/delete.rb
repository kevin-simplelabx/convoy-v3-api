# Delete Family (Admin only): the Family, its children, pending invites and its open bus service applications (withdrawn)
# go for every adult; their own accounts, shuttles and bookings stay, and what a school or company must keep stays with
# them. Refused while a child has a bus service, an accepted request or an unpaid bill (BusService.delete_blockers).
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

          self.class.discard!(@household)
        end
      end

      # Removes the Family (also AppAccountsPurgeJob, when its last adult is gone): its open bus service applications are
      # withdrawn in each company (else the company could still accept one for a child who no longer exists), then the
      # children, adults, invite links and the household. Call under the household's lock.
      def self.discard!(household)
        ConvoyApp::Parents.companies(household).each do |company|
          ConvoyApp::Parents.within(company) do
            BusRequest.from_household(household).where(kind: "new").where.not(status: "Withdrawn").find_each do |req|
              next unless ConvoyApp::Parents::Withdraw::ALLOWED.include?(req.live_status)

              req.update!(status: "Withdrawn")
              req.log!("Withdrawn: the Family was deleted in the Convoy App", by: "Parent")
            end
          end
        end
        household.dependants.each(&:discard!)
        household.members.delete_all
        household.invite_links.delete_all
        household.discard!
      end
    end
  end
end
