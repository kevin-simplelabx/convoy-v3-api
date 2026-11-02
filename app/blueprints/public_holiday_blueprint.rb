class PublicHolidayBlueprint < ApplicationBlueprint
  fields :date, :name, :observed
  field(:saturday) { |h| h.saturday? }
end
