# OpenAPI file for Apidog: .api-documents/convoy-v3-api.openapi.json
#   bin/rails api_docs:record    run the request specs and record their requests / responses (tmp/openapi/examples.json)
#   bin/rails api_docs:probe     GET every endpoint against the development seed data (tmp/openapi/probe.json)
#   bin/rails api_docs:openapi   build the file from routes + .api-documents/*.md + recorded examples
#   bin/rails api_docs:all       all three
namespace :api_docs do
  desc "Record API examples from the request specs"
  task :record do
    # bin/rails sets RAILS_ENV=development and dotenv loads DATABASE_URL (the development DB): keep them from the specs.
    env = { "OPENAPI" => "1", "RAILS_ENV" => "test", "DATABASE_URL" => nil, "QUEUE_DATABASE_URL" => nil }
    system(env, "bundle exec rspec spec/requests", exception: true)
  end

  desc "GET every endpoint against the development seed data"
  task probe: :environment do
    ApiDocs::Probe.call
  end

  desc "Build .api-documents/convoy-v3-api.openapi.json"
  task openapi: :environment do
    Rails.application.eager_load!
    file = Rails.root.join(".api-documents/convoy-v3-api.openapi.json")
    spec = ApiDocs::OpenApiBuilder.call
    File.write(file, JSON.pretty_generate(spec.as_json))
    count = spec[:paths].sum { |_path, ops| ops.size }
    puts "#{count} operations in #{spec[:tags].size} resources → #{file.relative_path_from(Rails.root)}"
  end

  desc "Record examples (specs + probe), then build the OpenAPI file"
  task all: %i[record probe openapi]
end
