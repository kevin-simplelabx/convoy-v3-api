# View Details: what the driver shared. id_number is masked unless the full number was asked for (reveal: true).
class DriverKycProfileBlueprint < Blueprinter::Base
  fields :email, :address, :date_of_birth, :nationality, :residential_status, :id_label, :licence_class,
         :licence_qualified_on, :vocational_licence_number, :vocational_licence_expires_on, :vocational_status, :shared_at
  field(:age) { |k| k.age }
  field(:id_number) { |k, options| options[:reveal] ? k.id_number : k.id_number_masked }
  field(:id_revealed) { |_k, options| !!options[:reveal] }
end
