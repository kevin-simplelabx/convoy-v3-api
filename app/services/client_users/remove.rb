# Remove a client user (Convoy OS Client Users, or Client Portal Settings › Users by someone who manages them). The person
# loses access to this client (kept for history); their portal account stays for other clients. People and teams that
# had them as manager lose that manager. Every client keeps a Super Admin.
module ClientUsers
  class Remove < ApplicationService
    def initialize(user:, actor: nil)
      @user = user
      @actor = actor
    end

    def call
      ClientUser.transaction do
        @user.client.lock!
        raise Error, "You cannot remove #{@user.name}" if @actor.is_a?(ClientUser) && !@actor.manages?(@user, :remove)

        @user.discard!
        PortalJwt.where(client_user: @user).update_all(client_user_id: nil) # rubocop:disable Rails/SkipsModelValidations
        ClientUser.where(manager_id: @user.id).update_all(manager_id: nil) # rubocop:disable Rails/SkipsModelValidations
        ClientTeam.where(manager_id: @user.id).update_all(manager_id: nil) # rubocop:disable Rails/SkipsModelValidations
        raise Error, "Keep at least one Super Admin for #{@user.client.name}" if @user.super? && !@user.client.users.kept.super.exists?
      end
      @user
    end
  end
end
