# Convoy's own data (Message Terms, Discover, Company Leads): only Convoy Admins see and change it.
class PlatformPolicy < ApplicationPolicy
  def index? = user.convoy_admin?
  def show? = index?
  def create? = index?
  def update? = index?
  def destroy? = index?
end
