# GET /portal/me: who is signed in, the organisation picked, what the person may do and which rail items show
# (Approvals for roles that approve, Shuttles when the client has shuttle routes, Invoices for billing roles; School Buses
# when the client, or a site the person covers, is a school: logic/app-feed.js schoolLinks).
module Portal
  class Shell < ApplicationService
    def initialize(client_user:)
      @user = client_user
      @client = client_user.client
    end

    def call
      {
        account: @user.portal_account.slice(:id, :email, :name),
        client_user: PortalAccountBlueprint.render_as_hash(@user),
        all_sites: @user.all_sites?,
        sites: @user.limit_to_sites(@client.sites, :id).order(:name).map { |s| { id: s.id, name: s.name } },
        can: ClientUserAccess::CAN.keys.index_with { |k| @user.can?(k) },
        menu: { approvals: approvals?, shuttles: shuttles?, school_buses: school_buses?, invoices: @user.can?(:billing) }
      }
    end

    private

    # Approvals: roles that can be asked, someone named in a flow step, or someone a booking's step asked.
    def approvals?
      @user.can?(:approve) || ClientApprovalStepPerson.exists?(client_user_id: @user.id) ||
        BookingApprovalStepPerson.joins(booking_approval_step: :approval).exists?(client_user_id: @user.id, booking_approvals: { status: "wait" })
    end

    def shuttles? = Trip.kept.where(client: @client, kind: "corporate_shuttle").exists?

    # A school linked to the client itself shows to everyone; a site's school only to people covering that site.
    def school_buses?
      @client.school.present? || @user.limit_to_sites(@client.sites.where.not(school_id: nil), :id).exists?
    end
  end
end
