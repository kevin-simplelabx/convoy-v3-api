# Settings › Users. Everyone sees themselves; people who manage users see those they manage (ClientUserAccess#manages?).
module Portal
  class ClientUserPolicy < ApplicationPolicy
    SITE_ROLES = %w[ssa sa sfin member].freeze

    def index? = true
    def create? = user.can?(:users)
    def update? = user.manages?(record, :edit)
    def destroy? = user.manages?(record, :remove)

    class Scope < ApplicationPolicy::Scope
      def resolve
        mine = scope.where(client_id: user.client_id).kept
        return mine.where(id: user.id) unless user.can?(:users)
        return mine if user.wide?
        return mine.where(role: SITE_ROLES) unless user.client_has_sites?

        shared = ClientUserSite.where(client_site_id: user.picked_site_ids).select(:client_user_id)
        mine.where(id: user.id).or(mine.where(role: SITE_ROLES, id: shared))
      end
    end
  end
end
