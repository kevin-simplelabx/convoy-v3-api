# Distances on the map.
module Geo
  EARTH_M = 6_371_000.0

  module_function

  # Metres between two [lat, lng] points (haversine).
  def metres(a, b)
    lat1, lng1, lat2, lng2 = [ *a, *b ].map { |v| v.to_f * Math::PI / 180 }
    h = (Math.sin((lat2 - lat1) / 2)**2) + (Math.cos(lat1) * Math.cos(lat2) * (Math.sin((lng2 - lng1) / 2)**2))
    2 * EARTH_M * Math.asin(Math.sqrt(h))
  end
end
