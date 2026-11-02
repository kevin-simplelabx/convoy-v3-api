class NoticePolicy < ApplicationPolicy
  def end_now? = write?
  def duplicate? = write?
end
