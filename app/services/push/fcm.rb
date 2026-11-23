# Firebase Cloud Messaging HTTP v1: one message to one phone token (Android, and iOS through the project's APNs key). The
# OAuth token comes from the service account (googleauth) and is reused until a minute before it expires.
module Push
  class Fcm
    SCOPE = "https://www.googleapis.com/auth/firebase.messaging".freeze
    # Error codes that mean the token is no use any more (app removed, token from another Firebase project, malformed).
    GONE = %w[UNREGISTERED SENDER_ID_MISMATCH].freeze

    def initialize(credentials_json)
      @project_id = JSON.parse(credentials_json).fetch("project_id")
      @credentials = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: StringIO.new(credentials_json), scope: SCOPE)
      @lock = Mutex.new
      @http = Faraday.new("https://fcm.googleapis.com", request: { open_timeout: 5, timeout: 10 })
    end

    # :sent, or :unregistered (forget the token). Raises Push::Error on anything else.
    def deliver(token:, title:, body:, data:)
      res = @http.post("/v1/projects/#{@project_id}/messages:send", { message: message(token, title, body, data) }.to_json,
                       "Authorization" => "Bearer #{access_token}", "Content-Type" => "application/json")
      return :sent if res.success?
      return :unregistered if gone?(res)

      raise Error, "FCM #{res.status}: #{res.body.to_s.truncate(300)}"
    rescue Faraday::Error, Signet::AuthorizationError => e
      raise Error, "FCM #{e.class}: #{e.message.truncate(300)}"
    end

    private

    def message(token, title, body, data)
      { token:, notification: { title:, body: }, data:,
        android: { priority: "high", notification: { sound: "default" } },
        apns: { headers: { "apns-priority" => "10" }, payload: { aps: { sound: "default" } } } }
    end

    def access_token
      @lock.synchronize do
        @credentials.fetch_access_token! if @credentials.access_token.nil? || @credentials.expires_within?(60)
        @credentials.access_token
      end
    end

    def gone?(res)
      error = JSON.parse(res.body.to_s)["error"] || {}
      codes = Array(error["details"]).filter_map { it["errorCode"] }
      res.status == 404 || codes.intersect?(GONE) || (error["status"] == "INVALID_ARGUMENT" && error["message"].to_s.include?("registration token"))
    rescue JSON::ParserError
      res.status == 404
    end
  end
end
