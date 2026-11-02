# Managed Clients > Add Site / Edit Site: name, address and pin; the site's own School Bus school; billing as its own
# legal entity with the people who get its invoices (billing_contacts: the whole list, in order). A site billed to the
# client keeps no billing details.
module ClientSites
  class Save < ApplicationService
    def initialize(site:, params:, user: nil)
      @site = site
      @params = params
      @user = user
    end

    def call
      ClientSite.transaction do
        @site.assign_attributes(@params.except(:billing_contacts))
        @site.created_by ||= @user if @site.new_record?
        clear_billing unless @site.own_billing?
        @site.save!
        save_contacts if @params.key?(:billing_contacts) || !@site.own_billing?
      end
      @site
    end

    private

    def clear_billing
      @site.assign_attributes(billing_name: nil, billing_uen: nil, billing_address: nil)
    end

    def save_contacts
      ClientBillingContact.replace!(@site, @site.own_billing? ? @params[:billing_contacts] : [])
    end
  end
end
