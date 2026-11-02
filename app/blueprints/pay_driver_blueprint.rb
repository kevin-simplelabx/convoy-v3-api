# A row of HR > Drivers: { driver:, vehicle:, scheme:, vehicle_type:, warning: } from Pay::DriverList.
class PayDriverBlueprint < Blueprinter::Base
  field(:id) { |r| r[:driver].id }
  field(:name) { |r| r[:driver].name }
  field(:phone) { |r| r[:driver].phone_display }
  field(:photo) { |r| r[:driver].decorate.file_info(:photo, versions: [ :thumb ]) }
  field(:age) { |r| r[:driver].kyc_profile&.age }
  field(:vehicle) { |r| r[:vehicle] && { id: r[:vehicle].id, plate: r[:vehicle].plate } }
  field(:vehicle_type) { |r| r[:vehicle_type] && { id: r[:vehicle_type].id, name: r[:vehicle_type].name } }
  field(:scheme_today) { |r| r[:scheme] && { id: r[:scheme].id, name: r[:scheme].name } }
  field(:warning) { |r| r[:warning] }

  view :detail do
    field(:pay_schemes) do |r|
      r[:driver].pay_schemes.map { |a| { id: a.id, pay_scheme: { id: a.pay_scheme.id, name: a.pay_scheme.name }, starts_on: a.starts_on, ends_on: a.ends_on, tag: a.tag } }
    end
    field(:vehicle_types) do |r|
      r[:driver].pay_vehicle_types.map do |a|
        scheme = Pay::DriverTerms.new(r[:driver], from: a.starts_on, to: a.starts_on).scheme_on([ a.starts_on, Date.current ].max)
        { id: a.id, vehicle_type: { id: a.vehicle_type.id, name: a.vehicle_type.name }, starts_on: a.starts_on, ends_on: a.ends_on, tag: a.tag,
          warning: Pay::DriverList.rate_warning(scheme, a.vehicle_type_id) }
      end
    end
    field(:min_start) { DriverPayScheme.min_start }
    field(:default_scheme) { PayScheme.kept.find_by(is_default: true)&.then { |s| { id: s.id, name: s.name } } }
  end
end
