class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "Convoy <no-reply@convoy.sg>")
  layout "mailer"
end
