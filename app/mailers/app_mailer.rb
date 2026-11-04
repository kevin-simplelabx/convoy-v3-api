# Emails to Convoy App people. Delivered in the background; until SMTP is set up they are only logged.
class AppMailer < ApplicationMailer
  # A mobile number that was on this account was verified by someone else (numbers get reissued) and moved to them.
  def identity_moved(email, mobile)
    @mobile = mobile
    mail to: email, subject: "#{mobile} moved off your Convoy account"
  end

  # Delete Account was asked: removed after 30 days unless they sign in again.
  def delete_requested(email, on)
    @on = on
    mail to: email, subject: "Your Convoy account will be deleted"
  end
end
