# A work email leaves the account: the invitations it found (not answered yet) go with it, so nothing waits on an email
# the person no longer has. Accepted links block removing the email (Uses), declined ones stay as the person's answer.
module ConvoyApp
  module Links
    class Release < ApplicationService
      def initialize(identity:)
        @identity = identity
      end

      def call
        return unless @identity.email? && @identity.work?

        ActsAsTenant.without_tenant do
          ClientRider.where(app_account_id: @identity.app_account_id, matched_email: @identity.value, status: "invited").find_each(&:destroy!)
          ClientUser.where(app_account_id: @identity.app_account_id, app_matched_email: @identity.value, app_link_status: "invited").find_each do |user|
            user.update!(app_account_id: nil, app_link_status: nil, app_matched_email: nil)
          end
        end
      end
    end
  end
end
