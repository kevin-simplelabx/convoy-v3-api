# Convoy App › Household › Add Family Members: Quick Invite (a link) and Manual Invite (the phone's contacts). Any adult.
module Api
  module V1
    module ConvoyApp
      class HouseholdInvitesController < HouseholdBaseController
        # POST /app/household/invite_link → { token, url, message, expires_at } (the live link, a new one after 7 days)
        def link
          invite = ::ConvoyApp::Households::InviteLink.call(household:, account: current_account)
          render json: { data: { token: invite.token, url: invite.url, expires_at: invite.expires_at, message: invite_message(invite) } }
        end

        # POST /app/household/invites/check { contacts: [{ name, phone }] }
        #   → [{ name, phone, valid, on_convoy, in_household }]  (on_convoy: gets an in-app invite; in_household: not selectable)
        def check
          rows = ::ConvoyApp::Households::Contacts.call(household:, contacts: contacts_param)
          render json: { data: rows.map { it.except(:account_id) } }
        end

        # POST /app/household/invites { contacts: [{ name, phone, relationship }] }
        #   → { invited: [adult], link_for: [{ name, phone }] }  (link_for = no Convoy account: send them the Quick Invite link)
        def create
          result = ::ConvoyApp::Households::InviteContacts.call(household:, inviter: current_account, contacts: contacts_param)
          invited = result[:invited].map { HouseholdMember.includes(app_account: :identities).find(it.id).decorate }
          render json: { data: { invited: HouseholdAdultBlueprint.render_as_hash(invited, viewer: current_member), link_for: result[:link_for] } },
                 status: :created
        end

        private

        def contacts_param = params.expect(contacts: [ %i[name phone relationship] ])

        def invite_message(link)
          "#{current_account.display_name} has invited you to join their Convoy for Family account to manage the family travel needs. " \
            "Join here: #{link.url}"
        end
      end
    end
  end
end
