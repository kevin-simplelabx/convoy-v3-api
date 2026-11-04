# A mobile or email typed in the Convoy App, checked and normalised: kind "mobile" / "email", value ("+6591882045" /
# "rachel@x.com") and display. Raises the message the screen shows when it is not valid.
module ConvoyApp
  class Target < ApplicationService
    Result = Data.define(:kind, :value) do
      def display = AppIdentity.new(kind:, value:).display
      def domain = kind == "email" ? value.split("@").last : nil
      def to_h = { kind:, value:, display: }
    end

    def initialize(mobile: nil, email: nil, kind: nil, value: nil)
      @kind = kind.presence || (mobile.present? ? "mobile" : "email")
      @value = value.presence || mobile.presence || email
    end

    def call
      raise ActionController::ParameterMissing, :mobile unless @value.present? && %w[mobile email].include?(@kind)

      value = ConvoyApp.normalize(@kind, @value)
      if @kind == "mobile"
        raise Error.new("Enter an 8-digit Singapore mobile number", details: { mobile: [ "is not valid" ] }) unless AppIdentity.valid_mobile?(value)
      elsif !AppIdentity.valid_email?(value)
        raise Error.new("Enter a valid email address", details: { email: [ "is not valid" ] })
      end
      Result.new(kind: @kind, value:)
    end
  end
end
