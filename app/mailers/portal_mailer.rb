# Emails to Client Portal people. Delivered in the background; until SMTP is set up they are only logged
# (and the code is shown on dev / staging when PORTAL_SHOW_CODE=1, see Portal::SessionsController).
class PortalMailer < ApplicationMailer
  def sign_in_code(account, code, purpose)
    @code = code
    @purpose = purpose
    @minutes = PortalSignInCode::TTL.in_minutes.to_i
    mail to: account.email, subject: "#{code} is your Client Portal code"
  end
end
