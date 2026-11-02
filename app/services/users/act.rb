# Row buttons of Settings > Users:
#   suspend   active    → suspended (cannot sign in; signed out everywhere)
#   activate  suspended → active (Turn back on)
#   remove    soft delete: gone from the list, signed out everywhere; the name stays on past records and the
#             email can be used for a new user
module Users
  class Act < ApplicationService
    include Guard

    ACTIONS = %w[suspend activate remove].freeze
    VERBS = { "suspend" => "suspend", "activate" => "turn back on", "remove" => "delete" }.freeze

    def initialize(actor:, user:, action:)
      @actor = actor
      @user = user
      @action = action.to_s
    end

    def call
      raise Error, "Unknown action" unless ACTIONS.include?(@action)

      guard_self!(@user, VERBS[@action])
      guard_owner!(@user)
      User.transaction do
        public_send(@action)
        keep_an_owner!(@user.company)
      end
      @user
    end

    def suspend
      @user.suspended!
      @user.allowlisted_jwts.delete_all
    end

    def activate = @user.active!

    def remove
      @user.discard!
      @user.allowlisted_jwts.delete_all
    end
  end
end
