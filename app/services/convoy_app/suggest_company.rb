# Suggest Convoy to My Company: a work email of the account whose domain links to nothing becomes a Company Lead for
# Convoy Admin. The person is named only when they agree. Returns the lead.
module ConvoyApp
  class SuggestCompany < ApplicationService
    def initialize(account:, identity:, company_name:, contact: nil, named: false)
      @account = account
      @identity = identity
      @company_name = company_name.to_s.squish
      @contact = contact.to_s.squish.presence
      @named = ActiveModel::Type::Boolean.new.cast(named)
    end

    def call
      raise Error, "Suggest Convoy from a work email" unless @identity.work?
      raise Error.new("Enter the company name", details: { company_name: [ "can't be blank" ] }) if @company_name.blank?

      CompanyLead.create!(domain: @identity.domain, company_name: @company_name.truncate(120), contact: @contact&.truncate(200),
                          named_name: @named ? @account.display_name : nil, named_via: @named ? @identity.value : nil,
                          source: "Convoy app", asked_at: Time.current)
    end
  end
end
