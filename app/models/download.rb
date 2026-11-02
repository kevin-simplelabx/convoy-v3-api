# Signed, expiring tokens for private files: { gid, mount, version } verified by DownloadsController.
module Download
  PURPOSE = :download
  TTL = 1.hour

  def self.token_for(record, mount, version = nil)
    verifier.generate({ "gid" => record.to_global_id.to_s, "mount" => mount.to_s, "version" => version&.to_s },
                      expires_in: TTL, purpose: PURPOSE)
  end

  # Returns the uploader (or its version) for a token, or nil when the token is bad, expired or the record is gone.
  # Tokens are only issued when a record is rendered to a user allowed to see it; tenant models are also
  # looked up inside the current tenant, so a leaked token cannot open another company's file.
  def self.resolve(token)
    data = verifier.verified(token, purpose: PURPOSE) or return nil
    record = GlobalID::Locator.locate(data["gid"]) or return nil
    uploader = record.public_send(data["mount"])
    data["version"] ? uploader.versions[data["version"].to_sym] : uploader
  rescue ActiveRecord::RecordNotFound, NoMethodError
    nil
  end

  def self.verifier
    Rails.application.message_verifier(:downloads)
  end
end
