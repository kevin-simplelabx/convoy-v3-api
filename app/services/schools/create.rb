# New School: the postal code places it on the map through OneMap (the address defaults to OneMap's).
module Schools
  class Create < ApplicationService
    def initialize(params)
      @params = params
    end

    def call
      postal = @params[:postal].to_s.gsub(/\D/, "")
      raise Error, "Postal code must be 6 digits" unless postal.match?(/\A\d{6}\z/)

      point = Geo::OneMap.lookup(postal) or raise Error, "Postal code not found on OneMap"
      School.create!(@params.merge(postal:, address: @params[:address].presence || point[:address], lat: point[:lat], lng: point[:lng]))
    rescue Geo::OneMap::Unavailable
      raise Error, "OneMap cannot be reached. Try again in a moment"
    end
  end
end
