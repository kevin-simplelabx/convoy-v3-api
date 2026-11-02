# OPENAPI=1 bundle exec rspec spec/requests (or bin/rails api_docs:record): records every API request the specs make
# into tmp/openapi/examples.json, read by `bin/rails api_docs:openapi`.
return unless ENV["OPENAPI"]

module OpenapiRecording
  RECORDER = ApiDocs::Recorder.new

  def process(...)
    super.tap { RECORDER.record(request, response) if request }
  end
end

ActionDispatch::Integration::Session.prepend(OpenapiRecording)

RSpec.configure do |config|
  config.after(:suite) { OpenapiRecording::RECORDER.write(ApiDocs::Recorder::SPECS) }
end
