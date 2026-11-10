# Add Application: a parent who applied outside the app, added to an academic year by an admin. Placed on the map from
# the postal code (OneMap) when it can be found; signed against the Payment & Refund Policy in use.
module BusRequests
  class Add < ApplicationService
    def initialize(year, params, user:)
      @year = year
      @params = params
      @user = user
    end

    def call
      postal = @params[:postal].to_s.gsub(/\D/, "")
      am = @params[:am] != false
      pm = @params[:pm] != false
      error = if @params[:child_name].blank? then "Enter the child's name"
      elsif @params[:parent_name].blank? then "Enter the parent's name"
      elsif postal.length != 6 then "Enter a 6-digit postal code"
      elsif !am && !pm then "Pick AM, PM or both"
      end
      raise Error, error if error

      hit = locate(postal)
      fee = @params[:fee_paid] != false
      now = Time.current
      school = @year.school
      ApplicationRecord.transaction do
        req = school.bus_requests.create!(
          academic_year: @year, kind: "new", source: "console", status: "Requested", submitted_at: now, am:, pm:, postal:,
          child_name: @params[:child_name].strip, parent_name: @params[:parent_name].strip, parent_phone: @params[:parent_phone].to_s.strip.presence,
          parent_email: @params[:parent_email].to_s.strip.presence, level: @params[:level].presence,
          address: @params[:address].to_s.strip.presence || hit&.dig(:address), lat: hit&.dig(:lat), lng: hit&.dig(:lng),
          start_on: @params[:start_on].presence || BusRequests.mid_settings(@year).start, fee_paid: fee,
          policy_version: SchoolPolicyVersion.current_for(school.policy_versions, now.to_date)&.version
        )
        req.log!("Added by #{@user.name} on the parent's behalf. Registration fee #{fee ? 'received' : 'not yet received'}", by: @user, at: now)
        req
      end
    end

    private

    def locate(postal)
      Geo::OneMap.lookup(postal)
    rescue Geo::OneMap::Unavailable
      nil
    end
  end
end
