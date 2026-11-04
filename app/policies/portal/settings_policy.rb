# Settings tabs without a record of their own: Logo and Colour (Super Admin, Admin), Sites (everyone, their sites),
# Billing Details (billing roles; the organisation only for organisation-wide roles, a site for people covering it).
module Portal
  class SettingsPolicy < ApplicationPolicy
    def sites? = true
    def brand? = user.can?(:brand)
    def billing? = user.can?(:billing)
    def organisation_billing? = billing? && user.wide?
    def site_billing? = billing? && record.is_a?(ClientSite) && record.own_billing? && user.covers?(record.id)
  end
end
