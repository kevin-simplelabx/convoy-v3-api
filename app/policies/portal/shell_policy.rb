# The portal shell (who am I, the rail, Role Permissions): everyone with a client account.
module Portal
  class ShellPolicy < ApplicationPolicy
    def show? = true
  end
end
