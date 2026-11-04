# Client Portal › Settings › Billing Details: who invoices are billed to — the organisation (organisation-wide roles)
# and each site billed as its own entity (people covering the site). Legal name, UEN and address are on the client
# (billing_name, uen, billing_address) or the site (billing_name, billing_uen, billing_address). The portal's one
# Billing Email and one Attention map onto the people on the invoices (client_billing_contacts): the first person the
# invoice goes To, and the person under Attention; the others added in Convoy OS stay as they are.
module Portal
  class BillingDetails < ApplicationService
    CLIENT_KEYS = %w[billing_name uen billing_address].freeze
    SITE_KEYS = %w[billing_name billing_uen billing_address].freeze

    # The entities this person may see and edit.
    def self.list(user)
      client = user.client
      sites = user.limit_to_sites(client.sites.where(own_billing: true), :id).includes(:billing_contacts).order(:name)
      ([ (client if user.wide?) ] + sites.to_a).compact.map { |b| entity(b) }
    end

    def self.entity(billable)
      people = billable.billing_contacts.to_a
      site = billable.is_a?(ClientSite)
      {
        kind: site ? "site" : "organisation", site_id: (billable.id if site), site_name: (billable.name if site),
        legal_name: site ? billable.billing_name : billable.bill_name, uen: site ? billable.billing_uen : billable.uen,
        billing_address: billable.billing_address, billing_email: to_person(people)&.email,
        attention: people.find(&:attention)&.name, changed: changed(billable, site ? SITE_KEYS : CLIENT_KEYS)
      }
    end

    def self.to_person(people) = people.find { |p| p.send_to? && p.email.present? }

    # The latest change to these details or their people, and whether it was made in the portal.
    def self.changed(billable, keys)
      audits = Audited::Audit.where(auditable: billable)
                             .or(Audited::Audit.where(auditable_type: "ClientBillingContact", auditable_id: billable.billing_contacts.select(:id)))
                             .reorder(created_at: :desc).limit(20).includes(:user)
      audit = audits.find { |a| a.auditable_type == "ClientBillingContact" || a.audited_changes.keys.intersect?(keys) }
      audit && { by: audit.user&.name || audit.username, at: audit.created_at, in_portal: audit.user_type == "ClientUser" }
    end

    def initialize(billable:, params:)
      @billable = billable
      @params = params.to_h.symbolize_keys.transform_values { |v| v.to_s.strip.presence }
    end

    def call
      check!
      @billable.class.transaction do
        if @billable.is_a?(ClientSite)
          @billable.update!(billing_name: @params[:legal_name], billing_uen: @params[:uen], billing_address: @params[:billing_address])
        else
          @billable.update!(billing_name: (@params[:legal_name] unless @params[:legal_name] == @billable.name),
                            uen: @params[:uen], billing_address: @params[:billing_address])
        end
        save_people
      end
      self.class.entity(@billable.reload)
    end

    private

    def check!
      raise Error, "Enter the legal name" if @params[:legal_name].blank?
      raise Error, "Enter the billing email" if @params[:billing_email].blank?
      raise Error, "Check the billing email" unless @params[:billing_email].match?(URI::MailTo::EMAIL_REGEXP)
      raise Error, "Enter the billing address" if @params[:billing_address].blank?
      raise Error, "Check the UEN" if @params[:uen] && !Uen.normalize(@params[:uen]).to_s.match?(Uen::FORMAT)
    end

    def save_people
      people = @billable.billing_contacts.to_a
      to = self.class.to_person(people)
      att = people.find(&:attention)
      to ? to.update!(email: @params[:billing_email]) : add_person(email: @params[:billing_email])
      if @params[:attention]
        att ? att.update!(name: @params[:attention]) : add_person(name: @params[:attention], attention: true)
      elsif att
        att.email.present? ? att.update!(attention: false) : att.destroy!
      end
    end

    def add_person(**attrs)
      raise Error, "Up to #{ClientBillingContact::MAX} people get the invoices" if @billable.billing_contacts.count >= ClientBillingContact::MAX

      @billable.billing_contacts.create!(company_id: @billable.company_id, send_as: "to",
                                         position: @billable.billing_contacts.maximum(:position).to_i + 1, **attrs)
    end
  end
end
