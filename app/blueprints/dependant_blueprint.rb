# A child of the Household. status = the bus badge (ConvoyApp::Households::BusService; "No Bus Yet" until a request exists);
# pass statuses: (BusService.statuses) when rendering every child, to read the companies once.
class DependantBlueprint < Blueprinter::Base
  identifier :id
  fields :name, :first_name, :birth_date, :level, :gender, :student_id, :medical_tags, :medical_note

  field(:school) { |d| { id: d.school_id, name: d.school_name } }
  field(:photo) { |d| d.photo_info }
  field(:status) { |d, o| o[:statuses] ? o[:statuses][d.id] || ConvoyApp::Households::BusService::NONE : ConvoyApp::Households::BusService.status(d) }
end
