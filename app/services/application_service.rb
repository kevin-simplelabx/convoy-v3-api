# Service objects: ExampleService.call(...) runs #call on a new instance.
class ApplicationService
  def self.call(...) = new(...).call

  # Raised for a business rule the user can fix; rendered as 422 with the message.
  class Error < StandardError; end
end
