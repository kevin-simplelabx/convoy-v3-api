# Default rules: anyone signed in to the company may read; changes need a company user (Convoy Admin is view only).
# Records are already limited to the current company by acts_as_tenant; policies decide what the user may do.
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = true
  def show? = true
  def create? = write?
  def new? = create?
  def update? = write?
  def edit? = update?
  def destroy? = write?

  private

  def write?
    !user.convoy_admin?
  end

  def permitted?(permission)
    write? && user.can?(permission)
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope.all
    end

    private

    attr_reader :user, :scope
  end
end
