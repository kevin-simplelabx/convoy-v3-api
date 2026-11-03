# Convoy Admin sees and creates every company and sets the platform fields (add-ons, caps, status);
# in a company, users with the Users permission edit their company's settings (everyone else: view only).
# The country is picked once, then locked: a change is a CompanyCountryRequest.
class CompanyPolicy < ApplicationPolicy
  PLATFORM_FIELDS = %i[code country status school_run_enabled route_list_import_enabled external_vehicle_cap].freeze
  SETTINGS_FIELDS = %i[name short_name theme_color logo remove_logo timezone date_format time_format
                       observed_holidays business_units_enabled
                       ops_phone ops_hours ops_whatsapp ops_email depot_address].freeze
  # The full name is set when Convoy opens the account.
  COMPANY_FIELDS = (SETTINGS_FIELDS - %i[name]).freeze

  def index? = true
  def show? = user.convoy_admin? || record.id == user.company_id
  def create? = user.convoy_admin?
  def update? = user.convoy_admin? || (record.id == user.company_id && user.can?(:users))
  def destroy? = false

  def permitted_attributes
    return SETTINGS_FIELDS + PLATFORM_FIELDS if user.convoy_admin?

    record.is_a?(Company) && !record.country_locked? ? COMPANY_FIELDS + %i[country] : COMPANY_FIELDS
  end

  class Scope < Scope
    def resolve
      user.convoy_admin? ? scope.all : scope.where(id: user.company_id)
    end
  end
end
