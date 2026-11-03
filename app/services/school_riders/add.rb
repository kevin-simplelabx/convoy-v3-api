# Add Rider (by hand): no list, counts from its start to its end date. Placed on the map now when OneMap knows the
# postal code; otherwise saved with No Location (`located: false` tells the screen to say so).
module SchoolRiders
  class Add < ApplicationService
    def initialize(school:, params:, user:)
      @school = school
      @params = params
      @user = user
    end

    def call
      p = @params
      first = p[:first_name].to_s.strip
      last = p[:last_name].to_s.strip
      raise Error, "Enter a first name or last name" if first.empty? && last.empty?

      order = p[:name_order] == "first" ? "first" : "last"
      days = SchoolRider.parse_days(p[:cca_days].is_a?(Array) ? p[:cca_days].join(";") : p[:cca_days]) or raise Error, "CCA days must be days like Mon;Wed"
      rider = @school.riders.new(
        p.slice(:gender, :grade, :address, :starts_on, :ends_on, :parent_name, :parent_contact, :remarks)
         .merge(rid: p[:rid].presence || next_rid, first_name: first.presence, last_name: last.presence, name_order: order,
                name: [ first, last ].compact_blank.then { order == "first" ? it : it.reverse }.join(" "),
                postal: p[:postal].to_s.gsub(/\D/, ""), am: p.fetch(:am, true), pm: p.fetch(:pm, true), cca_days: days,
                source: "manual", created_by: @user)
      )
      rider.save!
      locate(rider)
      rider
    end

    private

    def next_rid
      n = @school.riders.manual.where("rid ~ '^M-[0-9]+$'").pluck(Arel.sql("MAX(SUBSTRING(rid FROM 3)::int)")).first.to_i
      "M-#{(n + 1).to_s.rjust(4, '0')}"
    end

    def locate(rider)
      Locate.call(SchoolRider.where(id: rider.id))
      rider.reload
    rescue Geo::OneMap::Unavailable
      rider
    end
  end
end
