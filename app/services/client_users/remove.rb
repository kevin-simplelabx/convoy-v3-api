# Client Users card: Remove user. The person loses access to this client (kept for history); their portal account stays
# for other clients. Every client keeps a Super Admin.
module ClientUsers
  class Remove < ApplicationService
    def initialize(user:)
      @user = user
    end

    def call
      ClientUser.transaction do
        @user.discard!
        PortalJwt.where(client_user: @user).update_all(client_user_id: nil) # rubocop:disable Rails/SkipsModelValidations
        raise Error, "Keep at least one Super Admin for #{@user.client.name}" if @user.super? && !@user.client.users.kept.super.exists?
      end
      @user
    end
  end
end
