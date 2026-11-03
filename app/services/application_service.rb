# Service objects: ExampleService.call(...) runs #call on a new instance.
class ApplicationService
  def self.call(...) = new(...).call

  # Raised for a business rule the user can fix; rendered as 422 with the message (code "invalid" unless given, and
  # details when the screen needs more, such as what a confirmation should list).
  class Error < StandardError
    attr_reader :code, :details

    def initialize(message = nil, code: nil, details: nil)
      super(message)
      @code = code
      @details = details
    end
  end
end
