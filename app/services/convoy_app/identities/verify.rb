# Mobile and Emails, step 2: the code for a mobile / email from step 1 (same kind, tag, value, replace). Adds it verified,
# replaces the personal one on Change, or renews a work email on Verify Again. A mobile on another account moves here
# (numbers get reissued; nothing else comes with it and the old owner is told by email); an email on another account is
# refused (accounts are not joined). Returns { identity, outcome: added | changed | reverified | moved }.
module ConvoyApp
  module Identities
    class Verify < ApplicationService
      def initialize(account:, code:, **input)
        @account = account
        @code = code
        @input = input
      end

      def call
        ok = Check.call(account: @account, **@input)
        input = ok[:target]
        tag = ok[:tag]
        AppSignInCode.check!(input.value, @code, purpose: :verify, account: @account)

        AppAccount.transaction do
          @account.lock!
          existing = AppIdentity.lock.find_by(kind: input.kind, value: input.value)
          if existing&.app_account_id == @account.id
            existing.update!(verified_at: Time.current)
            next { identity: existing, outcome: "reverified" }
          end

          outcome = "added"
          if existing
            raise Error, "This email is on another Convoy account. Sign in with it there" if existing.email?

            move!(existing)
            outcome = "moved"
          end
          old = @account.identities.find { it.kind == input.kind && it.personal? } if tag == "personal"
          if old
            old.destroy!
            outcome = "changed" if outcome == "added"
          end
          identity = @account.identities.create!(kind: input.kind, tag:, value: input.value, verified_at: Time.current)
          { identity:, outcome: }
        end
      end

      private

      def move!(existing)
        from = existing.app_account
        existing.destroy!
        AppIdentityMove.create!(kind: existing.kind, value: existing.value, from_app_account: from, to_app_account: @account, moved_at: Time.current)
        email = from.identities.reload.find(&:email?)
        AppMailer.identity_moved(email.value, existing.display).deliver_later if email
      end
    end
  end
end
