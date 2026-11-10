# Edit a rider added by hand (no list). A rider from an uploaded list changes with the next upload. A new postal code is
# placed on the map again (lat / lng cleared first, as Locate only fills an empty position).
module SchoolRiders
  class Update < ApplicationService
    NAME_KEYS = %i[first_name last_name name_order].freeze

    def initialize(rider:, params:)
      @rider = rider
      @params = params
    end

    def call
      raise Error, "Riders from an uploaded list change with the next upload" unless @rider.manual?

      attrs = @params.slice(:gender, :grade, :address, :starts_on, :ends_on, :parent_name, :parent_contact, :remarks, :am, :pm)
      attrs[:cca_days] = cca_days if @params.key?(:cca_days)
      attrs.merge!(name_attrs) if NAME_KEYS.any? { @params.key?(it) }
      postal = @params[:postal].to_s.gsub(/\D/, "") if @params.key?(:postal)
      relocate = postal.present? && postal != @rider.postal
      attrs.merge!(postal:, lat: nil, lng: nil) if relocate
      @rider.update!(attrs)
      locate if relocate
      @rider
    end

    private

    def cca_days
      value = @params[:cca_days]
      SchoolRider.parse_days(value.is_a?(Array) ? value.join(";") : value) or raise Error, "CCA days must be days like Mon;Wed"
    end

    def name_attrs
      order = @params.fetch(:name_order, @rider.name_order) == "first" ? "first" : "last"
      first = @params.fetch(:first_name, @rider.first_name).to_s.strip
      last = @params.fetch(:last_name, @rider.last_name).to_s.strip
      raise Error, "Enter a first name or last name" if first.empty? && last.empty?

      { name_order: order, first_name: first.presence, last_name: last.presence,
        name: [ first, last ].compact_blank.then { order == "first" ? it : it.reverse }.join(" ") }
    end

    def locate
      Locate.call(SchoolRider.where(id: @rider.id))
      @rider.reload
    rescue Geo::OneMap::Unavailable
      @rider
    end
  end
end
