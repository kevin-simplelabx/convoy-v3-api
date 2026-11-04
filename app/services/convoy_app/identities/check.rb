# Whether a mobile / email may be added to an account (Mobile and Emails), before its code is sent and again when the code
# comes back. Mobiles are personal; one mobile and one personal email (else Change, replace: true); a work email per
# domain and never a personal provider; not one already on the account, except a work email being verified again.
# Returns { target, tag, replace, reverify }.
module ConvoyApp
  module Identities
    class Check < ApplicationService
      def initialize(account:, kind:, value:, tag: nil, replace: false)
        @account = account
        @target = Target.call(kind:, value:)
        @tag = @target.kind == "mobile" ? "personal" : tag.to_s.presence || "personal"
        @replace = ActiveModel::Type::Boolean.new.cast(replace) || false
      end

      def call
        raise Error.new("Choose personal or work", details: { tag: [ "is not valid" ] }) unless %w[personal work].include?(@tag)

        mine = @account.identities.find { it.kind == @target.kind && it.value == @target.value }
        reverify = mine&.work? && @tag == "work"
        unless reverify
          raise Error, "Already on your account" if mine

          @tag == "work" ? check_work! : check_personal!
        end
        { target: @target, tag: @tag, replace: @replace, reverify: !!reverify }
      end

      private

      def check_work!
        if ConvoyApp.free_mail?(@target.domain)
          raise Error.new("Gmail, Outlook and other personal providers can't be a work email. Add it as your personal email instead",
                          details: { value: [ "is a personal provider" ] })
        end
        raise Error, "You already have a work email at #{@target.domain}" if @account.work_emails.any? { it.domain == @target.domain }
      end

      def check_personal!
        return if @replace || @account.identities.none? { it.kind == @target.kind && it.personal? }

        raise Error, @target.kind == "mobile" ? "Only one mobile number. Use Change Mobile" : "Only one personal email. Use Change Personal Email"
      end
    end
  end
end
