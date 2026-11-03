# A URA Master Plan 2019 subzone (data.gov.sg, Singapore Open Data Licence), simplified to 5 decimals: its code names new
# stops ("BDSZ03-0001"). Platform data, loaded by the seed.
# == Schema Information
#
# Table name: ura_subzones
# Database name: primary
#
#  id                 :bigint           not null, primary key
#  code               :string           not null
#  max_lat            :float            not null
#  max_lng            :float            not null
#  min_lat            :float            not null
#  min_lng            :float            not null
#  name               :string           not null
#  planning_area      :string           not null
#  planning_area_code :string           not null
#  region             :string           not null
#  rings              :jsonb            not null
#
# Indexes
#
#  index_ura_subzones_on_code                 (code) UNIQUE
#  index_ura_subzones_on_min_lat_and_max_lat  (min_lat,max_lat)
#
class UraSubzone < ApplicationRecord
  # The subzone a point is in, or nil (bounding box first, then the rings).
  def self.at(lat, lng)
    return nil if lat.nil? || lng.nil?

    where("min_lat <= :lat AND max_lat >= :lat AND min_lng <= :lng AND max_lng >= :lng", lat: lat.to_f, lng: lng.to_f)
      .find { |z| z.rings.any? { Geo.inside?([ lat, lng ], it) } }
  end
end
