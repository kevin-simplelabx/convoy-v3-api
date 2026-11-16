# Manual Invite: tells which of the phone's contacts already have a Convoy account (they get an in-app invite; the rest get the
# link) and which are in the Family or invited already (shown but not selectable). Never a search of Convoy users: only the
# numbers the person picked are looked at.
module ConvoyApp
  module Households
    class Contacts < ApplicationService
      MOBILE = /\A\+65[89]\d{7}\z/

      def initialize(household:, contacts:)
        @household = household
        @contacts = Array(contacts).map { it.to_h.symbolize_keys }
      end

      def call
        phones = @contacts.map { phone_of(it) }
        accounts = AppIdentity.where(kind: "mobile", value: phones.compact).index_by(&:value)
        taken = taken_ids(accounts.values.map(&:app_account_id))
        @contacts.zip(phones).map do |contact, phone|
          account_id = accounts[phone]&.app_account_id
          { name: contact[:name].to_s.squish, phone:, valid: phone.present?, on_convoy: account_id.present?,
            in_household: account_id.present? && taken.include?(account_id), account_id: }
        end
      end

      private

      def phone_of(contact)
        phone = AppIdentity.normalize_mobile(contact[:phone])
        phone if phone.match?(MOBILE)
      end

      def taken_ids(account_ids)
        @household.members.where(app_account_id: account_ids, status: %i[invited requested active]).pluck(:app_account_id)
      end
    end
  end
end
