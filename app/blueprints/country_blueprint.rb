class CountryBlueprint < Blueprinter::Base
  identifier :code
  fields :name, :live, :timezone, :currency, :phone_prefix, :map, :weather, :traffic
end
