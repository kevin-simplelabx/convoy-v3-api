# Privacy and Data › Delete Account: recorded now, removed after 30 days (AppAccountsPurgeJob) unless the person signs in
# again. Every phone is signed out; a confirmation goes to their email.
module ConvoyApp
  class RequestDelete < ApplicationService
    def initialize(account:)
      @account = account
    end

    def call
      @account.update!(delete_requested_at: Time.current)
      @account.jwts.destroy_all
      email = @account.personal_email || @account.identities.find(&:email?)
      AppMailer.delete_requested(email.value, (Time.current + AppAccount::DELETE_AFTER).to_date).deliver_later if email
      @account
    end
  end
end
