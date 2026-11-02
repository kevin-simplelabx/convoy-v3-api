# Anyone in the company may have a document read; only the person who started a read sees it.
class DocumentReadPolicy < ApplicationPolicy
  def show? = record.user_id == user.id

  class Scope < Scope
    def resolve = scope.where(user:)
  end
end
