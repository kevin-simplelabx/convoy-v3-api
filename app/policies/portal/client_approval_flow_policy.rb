# Settings › Approval Flows (Super Admin, Admin, Site Super Admin, Site Admin). The organisation's flow: organisation-wide
# roles; a site's own flow: people covering the site. Try a Booking: anyone who sets flows.
module Portal
  class ClientApprovalFlowPolicy < ApplicationPolicy
    def index? = user.can?(:rules)
    def try_booking? = index?
    def update? = index? && (record.organisation? ? user.wide? : user.covers?(record.client_site_id))
  end
end
