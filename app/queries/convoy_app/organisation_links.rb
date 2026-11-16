# The Organisations screen of one account: staff shuttle links (client_riders) and booking links (client users), with
# the transport company, the matched work email and whether the link is paused (that email is past its 12-month re-verify
# date: read-time state, nothing is written). Each company's clients are read inside that company.
#   ConvoyApp::OrganisationLinks.call(account:) -> [{ kind, id, status, state, organisation, company, role, ... }]
# state: invited | active | paused. Links of a removed client, a discarded client user or a suspended company are left out.
module ConvoyApp
  class OrganisationLinks
    def self.call(account:, today: Date.current) = new(account, today).call

    def initialize(account, today)
      @account = account
      @today = today
    end

    def call
      riders, users = own_rows
      companies = Company.active.where(id: (riders + users).map(&:company_id).uniq).index_by(&:id)
      identities = @account.identities.select { it.email? && it.work? }.index_by(&:value)
      links = companies.flat_map do |id, company|
        ActsAsTenant.with_tenant(company) do
          clients = Client.kept.where(id: (riders + users).select { it.company_id == id }.map(&:client_id)).index_by(&:id)
          approvers = ClientApprovalStepPerson.where(client_user_id: users.select { it.company_id == id }.map(&:id)).distinct.pluck(:client_user_id)
          riders.select { it.company_id == id && clients[it.client_id] }.map { rider_json(it, clients[it.client_id], company, identities) } +
            users.select { it.company_id == id && clients[it.client_id] }.map { user_json(it, clients[it.client_id], company, identities, approvers) }
        end
      end
      links.compact.sort_by { [ it[:organisation].downcase, it[:kind] ] }
    end

    private

    def own_rows
      ActsAsTenant.without_tenant do
        [ ClientRider.open_links.where(app_account_id: @account.id).to_a,
          ClientUser.kept.where(app_account_id: @account.id, app_link_status: %w[invited accepted]).includes(:created_by, :created_by_client_user).to_a ]
      end
    end

    def rider_json(rider, client, company, identities)
      build("shuttle", rider.id, rider.status, client, company, "Rider", rider.matched_email, identities, "Your employer", rider.created_at)
    end

    def user_json(user, client, company, identities, approvers)
      by = user.created_by&.shown_name || user.created_by_client_user&.name
      build("bookings", user.id, user.app_link_status, client, company, approvers.include?(user.id) ? "Approver" : "Booker", user.app_matched_email, identities, by || "Your school", user.created_at)
    end

    def build(kind, id, status, client, company, role, email, identities, added_by, added_at)
      identity = identities[email] or return nil
      paused = identity.links_paused?(@today)
      { kind:, id:, status:, state: paused ? "paused" : (status == "invited" ? "invited" : "active"), organisation: client.name,
        company: company.name, role:, matched_email: email, added_by:, added_on: added_at.to_date,
        paused_since: paused ? identity.reverify_due_on : nil }
    end
  end
end
