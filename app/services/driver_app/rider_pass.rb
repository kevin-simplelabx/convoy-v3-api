# A School Bus child's QR boarding pass: "CVR1-<rid>-<signature>". The Convoy App shows it on the child's card; the
# Driver app scans it and checks it against the run's list (code in the passenger row). Signed per company, so a pass
# cannot be made up or used at another company.
module DriverApp
  module RiderPass
    PREFIX = "CVR1".freeze

    module_function

    def code(company_id, rid) = "#{PREFIX}-#{rid}-#{signature(company_id, rid)}"

    # The rid of a valid pass for the company, else nil.
    def rid(company_id, code)
      prefix, *rest = code.to_s.strip.split("-")
      sig = rest.pop
      rid = rest.join("-")
      rid if prefix == PREFIX && rid.present? && ActiveSupport::SecurityUtils.secure_compare(sig.to_s, signature(company_id, rid))
    end

    def signature(company_id, rid) = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.secret_key_base, "rider-pass:#{company_id}:#{rid}")[0, 12]
  end
end
