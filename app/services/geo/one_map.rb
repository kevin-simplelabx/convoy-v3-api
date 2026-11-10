# Singapore postal codes on the map through the OneMap search API (public, no key), as the prototype does. Answers are
# kept in postal_geocodes. Tests swap the client for a fake (spec/support/fake_one_map.rb).
module Geo
  class OneMap
    URL = "https://www.onemap.gov.sg/api/common/elastic/search".freeze
    Unavailable = Class.new(StandardError)

    class << self
      attr_writer :client

      def client = @client ||= new

      # { lat:, lng:, address: } for a 6-digit postal code, or nil when OneMap does not know it.
      # Raises Unavailable when OneMap cannot be reached (nothing is cached then).
      def lookup(postal)
        postal = postal.to_s.gsub(/\D/, "")
        return nil unless postal.match?(/\A\d{6}\z/)

        row = PostalGeocode.find_by(country: "SG", postal:)
        return row.point if row && !row.stale?

        hit = client.search(postal)
        PostalGeocode.upsert({ country: "SG", postal:, found: hit.present?, lat: hit&.dig(:lat), lng: hit&.dig(:lng), address: hit&.dig(:address),
                               looked_up_at: Time.current }, unique_by: %i[country postal])
        hit
      end
    end

    def search(postal)
      res = Faraday.get(URL, { searchVal: postal, returnGeom: "Y", getAddrDetails: "Y", pageNum: 1 }) { it.options.timeout = 8 }
      raise Unavailable, "OneMap answered #{res.status}" unless res.success?

      body = JSON.parse(res.body)
      raise Unavailable, "OneMap refused the request: #{body['error']}" if body["error"].present? # not "postal code not found": never cached as that

      row = Array(body["results"]).find { it["POSTAL"] == postal }
      row && { lat: row["LATITUDE"].to_f, lng: row["LONGITUDE"].to_f, address: [ row["BLK_NO"], row["ROAD_NAME"] ].compact_blank.join(" ") }
    rescue Faraday::Error, JSON::ParserError => e
      raise Unavailable, e.message
    end
  end
end
