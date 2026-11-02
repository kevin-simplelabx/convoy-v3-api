# Who may act on whom in Settings > Users: only a Super Admin acts on a Super Admin or makes one, nobody suspends
# or deletes themselves, and the company always keeps at least one active Super Admin.
module Users
  module Guard
    private

    def guard_owner!(target)
      raise ApplicationService::Error, "Only a Super Admin can change a Super Admin" if target.owner? && !@actor.owner?
    end

    def guard_self!(target, verb)
      raise ApplicationService::Error, "You can't #{verb} yourself" if target.id == @actor.id
    end

    # Call after the change, inside the transaction.
    def keep_an_owner!(company)
      return if company.users.kept.active.where(owner: true).exists?

      raise ApplicationService::Error, "There must always be at least one active Super Admin"
    end
  end
end
