# Convoy App (the consumer app: parents, shuttle staff, people who book buses): one account per person across every
# company, signed in with any mobile or email they verified.
module ConvoyApp
  module_function

  # Personal mail providers: never a work email (Mobile and Emails › Add Work Email).
  FREE_MAIL = %w[gmail.com googlemail.com hotmail.com outlook.com live.com msn.com yahoo.com yahoo.com.sg ymail.com icloud.com me.com
                 mac.com aol.com proton.me protonmail.com qq.com 163.com 126.com singnet.com.sg zoho.com gmx.com mail.com yandex.com].freeze

  # The one-time code. No SMS or email provider yet, so it is always the same (APP_OTP_CODE, default 123456) and nothing
  # is sent; swap this for a random code once codes go out.
  def otp_code = ENV["APP_OTP_CODE"].presence || "123456"

  def free_mail?(domain) = FREE_MAIL.include?(domain.to_s.downcase)

  # "+6591882045" or "rachel@x.com" from what was typed; kind :mobile / :email.
  def normalize(kind, value)
    kind.to_s == "mobile" ? AppIdentity.normalize_mobile(value) : value.to_s.strip.downcase
  end
end
