# Manual Invite › Send: contacts with a Convoy account get an in-app invite with the relationship the inviter chose (shown as
# Invited until they accept; no Admin approval needed). Contacts without an account are not invited here: the answer lists
# them (`link_for`) and the app sends them the Quick Invite link, so they ask to join and the Admin approves. The invitee gets
# an alert in their inbox.
module ConvoyApp
  module Households
    class InviteContacts < ApplicationService
      def initialize(household:, inviter:, contacts:)
        @household = household
        @inviter = inviter
        @contacts = Array(contacts).map { it.to_h.symbolize_keys }
      end

      def call
        raise Error, "Choose at least one contact" if @contacts.empty?

        rows = Contacts.call(household: @household, contacts: @contacts).zip(@contacts)
        raise Error, "Check the mobile number of #{rows.find { !it[0][:valid] }[0][:name].presence || 'a contact'}" if rows.any? { !it[0][:valid] }

        invitees = rows.select { it[0][:on_convoy] && !it[0][:in_household] }
        missing = invitees.find { HouseholdMember::RELATIONSHIPS.exclude?(it[1][:relationship]) }
        raise Error.new("Choose how #{missing[0][:name].split.first} is related", details: { relationship: [ "can't be blank" ] }) if missing

        invited = invitees.map { |info, contact| invite(info, contact[:relationship]) }
        { invited:, link_for: rows.reject { it[0][:on_convoy] }.map { it[0].slice(:name, :phone) } }
      end

      private

      def invite(info, relationship)
        @household.with_lock do
          member = @household.members.find_or_initialize_by(app_account_id: info[:account_id])
          member.assign_attributes(status: :invited, relationship:, invited_via: :manual, invited_by: @inviter, invite_phone: info[:phone])
          member.save!
          Alerts.safely { Alerts::Invites.family(member, by: @inviter) }
          member
        end
      end
    end
  end
end
