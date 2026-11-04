# Settings › Users › Teams: everyone sees them (team and manager on each person); Super Admins and Admins change them.
module Portal
  class ClientTeamPolicy < ApplicationPolicy
    def index? = true
    def create? = user.can?(:brand)
    def update? = create?
    def destroy? = create?

    class Scope < ApplicationPolicy::Scope
      def resolve = scope.where(client_id: user.client_id)
    end
  end
end
