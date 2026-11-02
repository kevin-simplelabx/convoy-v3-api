# Convoy Admin sees and creates every company and sets the platform fields (add-ons, caps, status);
# a company Admin edits their own company's settings (country is locked once set; a change is a request, later).
class CompanyPolicy < ApplicationPolicy
  PLATFORM_FIELDS = %i[code country status school_run_enabled route_list_import_enabled external_vehicle_cap].freeze
  SETTINGS_FIELDS = %i[name short_name theme_color logo timezone date_format time_format
                       observed_holidays business_units_enabled].freeze

  def index? = true
  def show? = user.convoy_admin? || record.id == user.company_id
  def create? = user.convoy_admin?
  def update? = user.convoy_admin? || (record.id == user.company_id && (user.admin? || user.owner?))
  def destroy? = false

  def permitted_attributes
    user.convoy_admin? ? SETTINGS_FIELDS + PLATFORM_FIELDS : SETTINGS_FIELDS
  end

  class Scope < Scope
    def resolve
      user.convoy_admin? ? scope.all : scope.where(id: user.company_id)
    end
  end
end
