# Base of the Household calls: the signed-in person's own Family (the one they are active in). Any adult may add children,
# invite, add photos and switch guardians; only the Admin approves Asked to Join and deletes the Family.
module Api
  module V1
    module ConvoyApp
      class HouseholdBaseController < BaseController
        before_action :require_household!

        private

        def current_member
          return @current_member if defined?(@current_member)

          @current_member = HouseholdMember.active.joins(:household).merge(Household.kept)
                                           .includes(household: [ { members: { app_account: :identities } }, { dependants: :dependant_guardians } ])
                                           .find_by(app_account_id: current_account.id)
        end

        def household = current_member.household

        def require_household!
          render_error(:not_found, "You are not in a Family yet", code: "no_household") unless current_member
        end

        def require_admin!
          render_error(:forbidden, "Only the Admin can do this", code: "admin_only") unless current_member.admin?
        end

        def render_household(status: :ok)
          fresh = HouseholdMember.includes(household: [ { members: { app_account: :identities } }, { dependants: :dependant_guardians } ]).find(current_member.id)
          render_data(fresh.household, HouseholdBlueprint, status:, viewer: fresh)
        end
      end
    end
  end
end
