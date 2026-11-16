# Accept / Not Me on a link the person was offered (Home card, Mobile and Emails after a work email). `kind` is "shuttle"
# (client_riders) or "bookings" (a client user). Only an invited link can be answered; a person cannot leave an accepted
# link (the app says "ask the office"). Accepting needs the work email to be verified within 12 months.
module ConvoyApp
  module Links
    class Answer < ApplicationService
      KINDS = %w[shuttle bookings].freeze

      def initialize(account:, kind:, id:, accept:)
        @account = account
        @kind = kind
        @id = id
        @accept = accept
      end

      def call
        record = find
        company = Company.active.find(record.company_id)
        ActsAsTenant.with_tenant(company) do
          record.with_lock do
            raise Error, "This was already answered" unless invited?(record)

            check_verified!(record) if @accept
            answer(record)
          end
        end
        record
      end

      private

      def find
        ActsAsTenant.without_tenant do
          case @kind
          when "shuttle" then ClientRider.where(app_account_id: @account.id).joins(:client).merge(Client.kept).find(@id)
          when "bookings" then ClientUser.kept.where(app_account_id: @account.id).joins(:client).merge(Client.kept).find(@id)
          else raise ActiveRecord::RecordNotFound
          end
        end
      end

      def invited?(record) = @kind == "shuttle" ? record.invited? : record.app_link_invited?

      def email(record) = @kind == "shuttle" ? record.matched_email : record.app_matched_email

      def check_verified!(record)
        identity = @account.identities.find_by(kind: "email", value: email(record))
        raise Error, "#{email(record)} is not on your account any more" unless identity
        raise Error, "Verify #{identity.value} again to accept" if identity.links_paused?
      end

      def answer(record)
        if @kind == "shuttle"
          record.update!(status: @accept ? "accepted" : "declined", responded_at: Time.current)
        else
          record.update!(app_link_status: @accept ? "accepted" : "declined", app_link_responded_at: Time.current)
        end
      end
    end
  end
end
