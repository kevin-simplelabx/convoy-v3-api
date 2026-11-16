# Daily: removes Convoy App accounts 30 days after Delete Account (the person did not sign in again), and abandoned ones
# (no phone signed in and no mobile / email left, or Create Your Account never finished). Company records (riders, bills,
# bookings) stay with the companies. A Family left with no adult is discarded.
class AppAccountsPurgeJob < ApplicationJob
  queue_as :default

  def perform
    purge(AppAccount.due_for_deletion)
    purge(AppAccount.abandoned)
    discard_empty_households
  end

  private

  # A Family whose last adult was removed with their account: nobody can open it any more.
  def discard_empty_households
    Household.kept.where.not(id: HouseholdMember.active.select(:household_id)).find_each do |household|
      household.with_lock do
        next if household.members.active.exists?

        household.dependants.each(&:discard!)
        household.members.delete_all
        household.invite_links.delete_all
        household.discard!
      end
    end
  end

  # Re-checks each one under its lock: someone who signs in while the job runs is kept.
  def purge(scope)
    scope.find_each do |account|
      account.with_lock { account.destroy! if scope.exists?(account.id) }
    end
  end
end
