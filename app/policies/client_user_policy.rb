# Client Users of a Managed Client: changed by any company user, like the client itself (Convoy Admin: view only).
class ClientUserPolicy < ApplicationPolicy
  def roles? = true
end
