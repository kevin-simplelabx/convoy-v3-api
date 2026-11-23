# The push client when no Firebase service account is set (development without FIREBASE_CREDENTIALS_JSON): logs, sends
# nothing, and the line keeps pushed_at empty.
module Push
  class Off
    def deliver(token:, title:, body:, data:)
      Rails.logger.info("[push off] #{title} — #{body} #{data.to_json} → #{token.truncate(16)}")
      :off
    end
  end
end
