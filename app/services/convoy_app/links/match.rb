# Finds the organisations a person's verified work emails belong to and invites them (never links without a tap):
# a work email on a Managed Client's `email_domains` makes a client_riders row (staff shuttle); a work email equal to a
# client user's email offers that user (teacher / booker link). Rows that exist (accepted, declined, removed) are left
# alone, so a "Not Me" or an office removal stays. Work emails past their re-verify date find nothing new.
# Reads across companies only to find candidates; each row is written inside its own company. A new invite is also an alert.
module ConvoyApp
  module Links
    class Match < ApplicationService
      def initialize(account:)
        @account = account
      end

      def call
        work = @account.identities.reload.select { it.email? && it.work? && !it.links_paused? }
        return if work.empty?

        clients, users = candidates(work)
        companies = Company.active.where(id: (clients.map(&:company_id) + users.map(&:company_id)).uniq).index_by(&:id)
        clients.each { |client| invite_rider(companies[client.company_id], client, work) if companies[client.company_id] }
        users.each { |user| invite_booker(companies[user.company_id], user) if companies[user.company_id] }
      end

      private

      def candidates(work)
        ActsAsTenant.without_tenant do
          clients = Client.kept.company.where("email_domains && ARRAY[?]::varchar[]", work.map(&:domain)).to_a
          users = ClientUser.kept.where(email: work.map(&:value), app_account_id: nil).where(client_id: Client.kept.select(:id)).to_a
          [ clients, users ]
        end
      end

      def invite_rider(company, client, work)
        email = work.find { client.email_domains.include?(it.domain) }.value
        ActsAsTenant.with_tenant(company) do
          rider = ClientRider.create_or_find_by!(client_id: client.id, app_account_id: @account.id) { it.matched_email = email }
          Alerts.safely { Alerts::Invites.employer(rider, client) } if rider.previously_new_record?
        end
      end

      def invite_booker(company, user)
        ActsAsTenant.with_tenant(company) do
          user.with_lock do
            next if user.app_account_id

            user.update!(app_account_id: @account.id, app_link_status: "invited", app_matched_email: user.email)
            Alerts.safely { Alerts::Invites.bookings(user) }
          end
        end
      end
    end
  end
end
