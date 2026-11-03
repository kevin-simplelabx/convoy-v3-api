# A licence on Driving Credentials, with its expiry badge. Render a decorated licence.
class DriverLicenceBlueprint < Blueprinter::Base
  identifier :id
  fields :kind, :name, :classes, :number, :issued_on, :expires_on

  field(:days_left) { |l| l.days_left }
  field(:expiry_status) { |l| l.expiry_status }
  field(:card_front) { |l| l.card_front_info }
  field(:card_back) { |l| l.card_back_info }
end
