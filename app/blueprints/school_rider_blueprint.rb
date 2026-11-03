# A rider of a school (Riders tab, route planning).
class SchoolRiderBlueprint < ApplicationBlueprint
  fields :rid, :name, :first_name, :last_name, :name_order, :gender, :grade, :address, :postal, :am, :pm, :cca_days,
         :starts_on, :ends_on, :parent_name, :parent_contact, :remarks, :source, :rider_dataset_id
  field(:lat) { |r| r.lat&.to_f }
  field(:lng) { |r| r.lng&.to_f }
  field(:located) { |r| r.located? }
end
