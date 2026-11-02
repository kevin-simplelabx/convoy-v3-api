# After a correct one-time code: a short signed token that lets the person set a password once (it stops working
# when the password changes or after 15 minutes).
module Portal
  module PasswordToken
    module_function

    def verifier = Rails.application.message_verifier(:portal_set_password)

    def generate(account) = verifier.generate({ "id" => account.id, "fp" => fingerprint(account) }, expires_in: 15.minutes)

    def account_for(token)
      data = verifier.verified(token.to_s)
      account = data && PortalAccount.find_by(id: data["id"])
      account if account && ActiveSupport::SecurityUtils.secure_compare(data["fp"].to_s, fingerprint(account))
    end

    def fingerprint(account) = Digest::SHA256.hexdigest("#{account.id}:#{account.encrypted_password}")[0, 16]
  end
end
