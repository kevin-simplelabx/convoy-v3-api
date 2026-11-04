# Client Portal policies: the user is the client user picked for the sign-in (ClientUserAccess). Records are already
# limited to that client's company by acts_as_tenant; each policy limits them to the client and the person's sites.
# Nothing is allowed unless a policy says so.
module Portal
  class ApplicationPolicy
    attr_reader :user, :record

    def initialize(user, record)
      @user = user
      @record = record
    end

    def index? = false
    def show? = false
    def create? = false
    def update? = false
    def destroy? = false

    class Scope
      def initialize(user, scope)
        @user = user
        @scope = scope
      end

      def resolve = scope.none

      private

      attr_reader :user, :scope
    end
  end
end
