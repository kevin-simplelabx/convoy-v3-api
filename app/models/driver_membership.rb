# A driver's record at one transport company, as the Convoy Driver app sees it: an own driver (Driver) or a driver of
# a managed operator (OperatorDriver). The app names it by key: "driver-4", "operator_driver-2".
module DriverMembership
  ORDER = %w[active pending past].freeze
  CLASSES = { "driver" => "Driver", "operator_driver" => "OperatorDriver" }.freeze

  module_function

  def key(member) = "#{member.model_name.singular}-#{member.id}"

  # own: the company's own driver; managed: drives for a sub-contractor (the operator) on the company's trips.
  def kind(member) = member.is_a?(OperatorDriver) ? "managed" : "own"

  # The company the driver works for: the operator for a managed driver, else the transport company.
  def employer_name(member) = member.is_a?(OperatorDriver) ? member.operator.name : member.company.name
end
