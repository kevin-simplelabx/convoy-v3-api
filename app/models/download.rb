# Signed, expiring tokens for private files: { gid, mount, version, company } verified by DownloadsController.
# The link alone opens the file (an <img src> cannot send the Bearer header), like a pre-signed URL.
module Download
  PURPOSE = :download
  TTL = 1.hour

  def self.token_for(record, mount, version = nil)
    verifier.generate({ "gid" => record.to_global_id.to_s, "mount" => mount.to_s, "version" => version&.to_s,
                        "company" => ActsAsTenant.current_tenant&.id }, expires_in: TTL, purpose: PURPOSE)
  end

  # Returns the uploader (or its version) for a token, or nil when the token is bad, expired or the record is gone.
  # Tokens are only issued when a record is rendered to a user allowed to see it; tenant models are looked up
  # inside the company the token was issued in, so a token cannot open another company's file.
  def self.resolve(token)
    data = verifier.verified(token, purpose: PURPOSE) or return nil
    record = locate(data["gid"], data["company"]) or return nil
    uploader = record.public_send(data["mount"])
    data["version"] ? uploader.versions[data["version"].to_sym] : uploader
  rescue ActiveRecord::RecordNotFound, ActsAsTenant::Errors::NoTenantSet, NoMethodError
    nil
  end

  def self.locate(gid, company_id)
    company = company_id && Company.find_by(id: company_id)
    return GlobalID::Locator.locate(gid) unless company

    ActsAsTenant.with_tenant(company) { GlobalID::Locator.locate(gid) }
  end

  def self.verifier
    Rails.application.message_verifier(:downloads)
  end
end
