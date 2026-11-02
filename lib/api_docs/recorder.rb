# Collects API calls (route, params, status, JSON body) as examples for the OpenAPI file; see ApiDocs::OpenApiBuilder.
module ApiDocs
  class Recorder
    SPECS = Rails.root.join("tmp/openapi/examples.json")
    PROBE = Rails.root.join("tmp/openapi/probe.json")
    MAX_ITEMS = 2

    attr_reader :examples

    def initialize
      @examples = Hash.new { |h, k| h[k] = [] }
    end

    def record(request, response)
      pattern = request.route_uri_pattern
      return unless pattern&.start_with?("/api/v1")

      examples["#{request.method} #{pattern.delete_suffix('(.:format)')}"] << {
        query: clean(request.query_parameters),
        body: unwrap(clean(request.request_parameters.except(*request.path_parameters.keys.map(&:to_s)))),
        multipart: request.media_type == "multipart/form-data",
        status: response.status,
        response: parse(response)
      }
    end

    def write(file)
      FileUtils.mkdir_p(file.dirname)
      File.write(file, JSON.pretty_generate(examples))
      puts "OpenAPI examples: #{examples.size} routes → #{file.relative_path_from(Rails.root)}"
    end

    private

    def parse(response)
      return if response.body.blank? || !response.media_type.to_s.include?("json")

      trim(JSON.parse(response.body))
    rescue JSON::ParserError
      nil
    end

    def clean(value)
      case value
      when Hash then value.to_h { |k, v| [ k.to_s, clean(v) ] }
      when Array then value.map { clean(it) }
      when ActionDispatch::Http::UploadedFile, Rack::Test::UploadedFile then { "__file" => value.original_filename }
      else value
      end
    end

    # Rails' params wrapper copies a JSON body under the controller's key ({ email, session: { email } }): drop the copy.
    def unwrap(body)
      body.reject { |key, value| value.is_a?(Hash) && body.size > 1 && value.all? { |k, v| k != key && body[k] == v } }
    end

    # Lists keep their first rows only, so examples stay readable.
    def trim(value)
      case value
      when Hash then value.transform_values { trim(it) }
      when Array then value.first(MAX_ITEMS).map { trim(it) }
      else value
      end
    end
  end
end
