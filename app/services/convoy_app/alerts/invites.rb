# Invitation alerts (tap opens Organisations or the Family invites on Home): an employer added the person to its staff
# shuttle, a school / company linked their work email to its bookings, an adult invited them into a Family.
module ConvoyApp
  module Alerts
    module Invites
      module_function

      def employer(rider, client)
        Alerts.write([ { app_account_id: rider.app_account_id, kind: "invite_employer", title: "#{client.name} added you to its staff shuttle",
                         body: "Matched by your work email #{rider.matched_email}.", company_id: rider.company_id, target: "organisations",
                         target_id: rider.id, dedupe_key: "invite:shuttle:#{rider.id}" } ])
      end

      def bookings(user)
        Alerts.write([ { app_account_id: user.app_account_id, kind: "invite_bookings", title: "#{user.client.name} invited you to book buses",
                         body: "Matched by your work email #{user.app_matched_email}.", company_id: user.company_id, target: "organisations",
                         target_id: user.id, dedupe_key: "invite:bookings:#{user.id}" } ])
      end

      def family(member, by:)
        Alerts.write([ { app_account_id: member.app_account_id, kind: "invite_family", title: "#{by.display_name} invited you to the #{member.household.name}",
                         body: "Accept to share the Family's children, school bus and fees.", target: "household_invitations",
                         target_id: member.id, dedupe_key: "invite:family:#{member.id}:#{member.updated_at.to_i}" } ])
      end
    end
  end
end
