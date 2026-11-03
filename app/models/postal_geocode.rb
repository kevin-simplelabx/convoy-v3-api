# A postal code looked up on OneMap (shared by every company): where it is, or that it was not found. Kept so the same
# code is not looked up twice; a "not found" is tried again after a week. Written by Geo::OneMap.
# == Schema Information
#
# Table name: postal_geocodes
# Database name: primary
#
#  id           :bigint           not null, primary key
#  address      :string
#  country      :string           default("SG"), not null
#  found        :boolean          not null
#  lat          :decimal(10, 7)
#  lng          :decimal(10, 7)
#  looked_up_at :timestamptz      not null
#  postal       :string           not null
#
# Indexes
#
#  index_postal_geocodes_on_country_and_postal  (country,postal) UNIQUE
#
class PostalGeocode < ApplicationRecord
  RETRY_NOT_FOUND = 7.days

  def stale? = !found && looked_up_at < RETRY_NOT_FOUND.ago
  def point = found ? { lat: lat.to_f, lng: lng.to_f, address: } : nil
end
