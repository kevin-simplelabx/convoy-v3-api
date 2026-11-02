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
      rows = @site.own_billing? ? Array(@params[:billing_contacts]).map { |r| r.to_h.symbolize_keys } : []
      rows = rows.reject { |r| r[:name].blank? && r[:email].blank? }
      raise Error, "Up to #{ClientBillingContact::MAX} people" if rows.size > ClientBillingContact::MAX
      if rows.any? { |r| r[:email].present? } && rows.none? { |r| r[:email].present? && r[:send_as].to_s != "cc" }
        raise Error, "Send the invoice To at least one person, not only CC"
      end

      @site.billing_contacts.delete_all
      rows.each_with_index do |r, i|
        @site.billing_contacts.create!(company_id: @site.company_id, name: r[:name], email: r[:email],
                                       send_as: r[:send_as].presence || "to", attention: ActiveModel::Type::Boolean.new.cast(r[:attention]) || false, position: i)
      end
    end
  end
end
