# Managed Clients > New Managed Client / Edit Details. Besides the client's own fields, a company client can be a
# School Bus school (school_id: the school is linked to this client) and pick that school's calendar
# (school_calendar_id: school holidays stop its buses). Individuals and transport companies have no school.
module Clients
  class Save < ApplicationService
    def initialize(params:, client: Client.new)
      @client = client
      @params = params
    end

    def call
      Client.transaction do
        @client.assign_attributes(@params.except(:school_id, :school_calendar_id))
        @client.save!
        link_school if @params.key?(:school_id) || !@client.company?
      end
      @client
    end

    private

    def link_school
      school = @client.company? && @params[:school_id].present? ? School.find(@params[:school_id]) : nil
      School.where(client_id: @client.id).where.not(id: school&.id).update_all(client_id: nil) # rubocop:disable Rails/SkipsModelValidations
      return unless school
      raise Error, "#{school.name} is already linked to #{school.client.name}" if school.client && school.client_id != @client.id
      if (site = ClientSite.find_by(school_id: school.id))
        raise Error, "#{school.name} is already linked to the site #{site.name} of #{site.client.name}"
      end

      school.client = @client
      school.calendar = calendar if @params.key?(:school_calendar_id)
      school.save!
    end

    def calendar
      return nil if @params[:school_calendar_id].blank?

      Calendar.kept.school.find_by(id: @params[:school_calendar_id]) || raise(Error, "Pick a school calendar")
    end
  end
end
