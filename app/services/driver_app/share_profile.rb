# Each company the driver works for (active membership) keeps a copy of the driver's profile (driver_kyc_profiles):
# what Drivers › View Details, HR and Finance (CPF) read. Refreshed whenever the driver changes the profile or joins a
# company; not after the driver leaves, so the company keeps the record as it was (decision 3.1, 26/10/2026).
module DriverApp
  class ShareProfile < ApplicationService
    def initialize(account:, members: nil)
      @account = account
      @members = members
    end

    def call
      (@members || @account.active_memberships(with: [ :kyc_profile ])).each do |member|
        ActsAsTenant.with_tenant(member.company) do
          kyc = member.kyc_profile || member.build_kyc_profile(company: member.company)
          kyc.assign_attributes(copy)
          kyc.shared_at ||= Time.current
          kyc.save! if kyc.changed?
        end
      end
    end

    private

    def copy
      @copy ||= begin
        dl = @account.licences.find { it.kind == "dl" }
        vl = @account.licences.find { it.kind == "vl" }
        { email: @account.email, address: @account.full_address, date_of_birth: @account.date_of_birth,
          nationality: @account.nationality, residential_status: @account.residential_status, id_number: @account.id_number,
          licence_class: dl&.classes, licence_qualified_on: dl&.issued_on,
          vocational_licence_number: vl&.number, vocational_licence_expires_on: vl&.expires_on,
          licences: @account.licences.map(&:to_share) }
      end
    end
  end
end
