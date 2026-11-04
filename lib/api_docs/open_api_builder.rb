# OpenAPI 3.0 file for Apidog, built from three sources:
#   - Rails routes under /api/v1: every endpoint (PUT is left out where PATCH does the same).
#   - .api-documents/*.md and <app>/*.md: menu folder, summary and description of the section that names the endpoint.
#   - recorded examples (ApiDocs::Recorder): request specs (OPENAPI=1) and the development probe of the seed data:
#     query params, request bodies, responses and their schemas.
# One folder per resource (controller) inside its menu: tags "Fleet / Vehicles" and x-apidog-folder "Fleet/Vehicles".
module ApiDocs
  class OpenApiBuilder
    DOCS = Rails.root.join(".api-documents")
    MENUS = { "convoy-os/scheduler.md" => "Scheduler", "convoy-os/trips.md" => "Trips", "convoy-os/fleet.md" => "Fleet", "convoy-os/settings.md" => "Settings", "convoy-os/clients.md" => "Clients", "convoy-os/hr.md" => "HR", "convoy-os/finance.md" => "Finance", "convoy-os/reports.md" => "Reports", "convoy-os/live-map.md" => "Live Map", "convoy-os/ops-control.md" => "Ops Control", "convoy-os/school-bus-setup.md" => "School Bus", "convoy-os/school-bus-money.md" => "School Bus", "convoy-os/school-bus-stops.md" => "School Bus", "convoy-os/school-bus-routes.md" => "School Bus", "convoy-os/school-bus-parents.md" => "School Bus", "convoy-os/school-bus-finance.md" => "School Bus", "convoy-os/school-bus-live.md" => "School Bus", "convoy-os/dashboard.md" => "Dashboard", "convoy-os/convoy-admin.md" => "Convoy Admin",
              "driver/auth.md" => "Driver App", "driver/profile.md" => "Driver App", "driver/runs.md" => "Driver App", "driver/driving.md" => "Driver App", "driver/gps.md" => "Driver App", "driver/disposal.md" => "Driver App", "driver/vehicle.md" => "Driver App", "driver/notifications.md" => "Driver App",
              "client-portal/auth.md" => "Client Portal", "client-portal/shell.md" => "Client Portal", "client-portal/settings.md" => "Client Portal", "client-portal/approval-flows.md" => "Client Portal", "client-portal/bookings.md" => "Client Portal", "client-portal/approvals.md" => "Client Portal", "client-portal/home.md" => "Client Portal",
              "client-portal/shuttles.md" => "Client Portal", "client-portal/notices.md" => "Client Portal", "client-portal/invoices.md" => "Client Portal", "client-portal/map.md" => "Client Portal", "README.md" => "Common" }.freeze
    # Folder = the Convoy OS menu that owns the resource (.notes/data-ownership.md), not the doc that first names it.
    FOLDERS = {
      "Common" => %w[sessions downloads document_reads banks],
      "Scheduler" => %w[scheduler occurrences replacements trip_assignments public/tracking],
      "Trips" => %w[trips trip_attachments trip_run_groups trip_stop_photos route_lists trip_history notices notice_templates
                    bookings booking_trips booking_attachments booking_cancel_requests booking_notifications
                    rate_cards rate_card_assignments],
      "Fleet" => %w[vehicles vehicle_teams vehicle_log_cards vehicle_insurance_policies vehicle_insurance_documents
                    vehicle_driver_schedules vehicle_types vehicle_type_requests drivers operator_drivers operators attendants
                    fuel fuel_entries fuel_alerts fuel_companies maintenance_visits workshops
                    external_share_links external_vehicle_submissions public/share_forms],
      "Clients" => %w[clients client_sites client_end_customers client_pickup_points client_users pickup_points],
      "HR" => %w[pay_rate_plans pay_schemes pay_drivers pay_earnings pay_simulator pay_bonuses pay_points pay_rewards pay_audit_log],
      "Finance" => %w[finance_settings client_invoices client_billing finance_documents finance_school_collections operator_payments vehicle_financials vehicle_pl],
      "Reports" => %w[reports],
      "Live Map" => %w[live_map],
      "Ops Control" => %w[ops_control],
      "School Bus" => %w[schools rider_datasets school_riders academic_years school_levels bus_sessions school_attendant_policies
                        fare_tables extra_charges school_policies school_payment_methods school_operator_pays
                        stops school_stops stop_photo_requests routing school_plans school_routes route_money rider_assignments
                        feasibility_studies families school_registrations bus_requests cca_rides school_bills school_documents school_payouts
                        school_live school_dashboard],
      "Dashboard" => %w[dashboard],
      "Convoy Admin" => %w[message_terms discover company_leads],
      "Client Portal" => %w[portal/sessions portal/passwords portal/me portal/roles portal/users portal/teams portal/settings portal/approval_flows portal/bookings portal/end_customers portal/approvals portal/pages portal/map],
      "Driver App" => %w[driver_app/sessions driver_app/companies driver_app/company driver_app/profiles driver_app/licences driver_app/vehicle driver_app/runs driver_app/positions driver_app/config driver_app/vehicle_handovers driver_app/notifications driver_app/notices],
      "Settings" => %w[users profiles companies countries country_requests calendars calendar_days public_holidays]
    }.flat_map { |folder, names| names.map { [ "api/v1/#{it}", folder ] } }.to_h.freeze
    ORDER = %w[Common Dashboard Ops\ Control Live\ Map Scheduler Trips School\ Bus Fleet Clients Reports Finance HR Settings Convoy\ Admin Client\ Portal Driver\ App Other].freeze
    MENTION = %r{`(GET|POST|PATCH|PUT|DELETE) (/[^`\s?]*)}
    PUBLIC = %w[api/v1/sessions#create api/v1/downloads#show api/v1/portal/sessions#lookup api/v1/portal/sessions#code
                api/v1/portal/sessions#verify api/v1/portal/sessions#create api/v1/portal/passwords#create
                api/v1/driver_app/sessions#code api/v1/driver_app/sessions#create api/v1/driver_app/sessions#email].freeze
    # Each app signs in with its own token (Convoy OS, Client Portal, Driver app); a public endpoint takes none.
    TOKEN_SCHEMES = { "api/v1/portal/" => "portalAuth", "api/v1/driver_app/" => "driverAuth" }.freeze

    CRUD = { "index" => "List %s", "show" => "Get %s", "create" => "Create %s", "update" => "Update %s",
             "destroy" => "Delete %s" }.freeze
    DESCRIPTION_LIMIT = 8_000

    def self.call = new.call

    def call
      {
        openapi: "3.0.1",
        info: { title: "Convoy V3 API", version: "1.0.0", description: DOCS.join("README.md").read },
        servers: [
          { url: "https://convoy-api-staging.convoy.sg/api/v1", description: "Staging" },
          { url: "http://localhost:3000/api/v1", description: "Local" }
        ],
        tags: tags,
        paths: paths,
        components: components,
        security: [ { bearerAuth: [] } ]
      }
    end

    private

    # ---- routes -------------------------------------------------------------------------------------------------

    def routes
      @routes ||= begin
        all = Rails.application.routes.routes.flat_map do |r|
          path = r.path.spec.to_s.delete_suffix("(.:format)")
          next [] if r.verb.blank? || !path.start_with?("/api/v1/")

          # `match via: [...]` gives one route with "PATCH|DELETE": one operation per verb.
          r.verb.split("|").map { |verb| { verb:, path:, controller: r.defaults[:controller], action: r.defaults[:action] } }
        end.uniq { [ it[:verb], it[:path] ] }
        patches = all.select { it[:verb] == "PATCH" }.map { [ it[:path], it[:action] ] }
        all.reject { it[:verb] == "PUT" && patches.include?([ it[:path], it[:action] ]) }
      end
    end

    def paths
      routes.group_by { openapi_path(it[:path]) }.transform_values do |list|
        list.to_h { [ it[:verb].downcase, operation(it) ] }
      end
    end

    def openapi_path(path) = path.delete_prefix("/api/v1").gsub(/:(\w+)/, '{\1}')

    def doc_key(verb, path) = "#{verb} #{path.delete_prefix('/api/v1').gsub(%r|/[:<{\d][^/]*|, "/:x").chomp('/')}"

    # ---- operations ---------------------------------------------------------------------------------------------

    def operation(route)
      examples = recorded["#{route[:verb]} #{route[:path]}"] || []
      mention = mention_for(route)
      {
        summary: summary(route, mention),
        description: description(route, mention),
        operationId: "#{route[:controller].delete_prefix('api/v1/').tr('/', '_')}_#{route[:action]}_#{route[:verb].downcase}",
        tags: [ tag_name(route[:controller]) ],
        "x-apidog-folder": folder(route[:controller]),
        parameters: path_params(route) + query_params(route, examples, mention),
        requestBody: request_body(route, examples),
        responses: responses(route, examples),
        security: security(route)
      }.compact
    end

    def summary(route, mention)
      title = mention&.dig(:heading) && clean_heading(mention[:section][:title])
      return title if title && title.split.size >= 2

      resource = resource_name(route[:controller]).downcase
      if CRUD[route[:action]]
        format(CRUD[route[:action]], route[:action] == "index" ? resource : resource.singularize)
      else
        "#{route[:action].humanize} (#{resource.singularize})"
      end
    end

    def clean_heading(title)
      text = title.gsub(/`[^`]*`/, "").sub(/\A[\d.]+\s*/, "").gsub(/\A[\s:—-]+|[\s:—-]+\z/, "")
      text.presence && text[0].upcase + text[1..]
    end

    def description(route, mention)
      parts = []
      parts << method_comment(route) if method_comment(route).present?
      if mention
        parts << mention[:section][:body].strip
        parts << "_Source: `#{mention[:file]}` § #{mention[:section][:title]}_"
      end
      parts << "`#{route[:controller].delete_prefix('api/v1/')}##{route[:action]}`"
      parts.join("\n\n").truncate(DESCRIPTION_LIMIT)
    end

    def protected?(route)
      return false if PUBLIC.include?("#{route[:controller]}##{route[:action]}")

      klass = controller_class(route[:controller])
      klass.nil? || [ Api::V1::BaseController, Api::V1::Portal::BaseController, Api::V1::DriverApp::BaseController ].any? { klass <= it }
    end

    # nil = the default (Convoy OS bearerAuth).
    def security(route)
      return [] unless protected?(route)

      scheme = TOKEN_SCHEMES.find { |prefix, _| route[:controller].start_with?(prefix) }&.last
      scheme && [ { scheme => [] } ]
    end

    # ---- parameters ---------------------------------------------------------------------------------------------

    def path_params(route)
      route[:path].scan(/:(\w+)/).flatten.map do |name|
        id = name == "id" || name.end_with?("_id")
        { name:, in: "path", required: true, description: "", schema: { type: id ? "integer" : "string" } }
      end
    end

    def query_params(route, examples, mention)
      return [] unless route[:verb] == "GET"

      found = {}
      examples.each { |ex| flatten_params(ex[:query]).each { |name, value| found[name] ||= value } }
      doc = mention ? doc_params(mention[:section][:body]) : {}
      if examples.any? { it.dig(:response, "meta", "page") }
        found["page"] ||= 1
        found["limit"] ||= 50
      end
      names = (found.keys + doc.keys).uniq
      names.map do |name|
        { name:, in: "query", required: false, description: doc[name].to_s, example: found[name],
          schema: { type: "string" } }.compact
      end
    end

    # Rows of a Param table: | `ownership[]` | own, managed | (several names in one cell are split).
    def doc_params(body)
      body.lines.each_with_object({}) do |line, out|
        cells = line.split("|").map(&:strip)
        next unless line.start_with?("|") && cells[1].to_s.start_with?("`")

        cells[1].scan(/`([^`]+)`/).flatten.each { |name| out[name.split(/[=\s]/).first] ||= cells[2].to_s }
      end
    end

    # { "q" => { "name_i_cont" => "x" }, "ownership" => ["own"] } → { "q[name_i_cont]" => "x", "ownership[]" => "own" }
    def flatten_params(hash, prefix = nil)
      hash.to_h.flat_map do |key, value|
        name = prefix ? "#{prefix}[#{key}]" : key.to_s
        case value
        when Hash then file?(value) ? [ [ name, value ] ] : flatten_params(value, name).to_a
        when Array then value.first.is_a?(Hash) ? flatten_params(value.first, "#{name}[]").to_a : [ [ "#{name}[]", value.first ] ]
        else [ [ name, value ] ]
        end
      end.to_h
    end

    # ---- bodies -------------------------------------------------------------------------------------------------

    def request_body(route, examples)
      return unless %w[POST PATCH PUT DELETE].include?(route[:verb])

      # An update with no recorded body takes the create's (same fields): PATCH /x/:id ← POST /x.
      if route[:action] == "update" && examples.none? { it[:body].present? }
        examples += recorded.fetch("POST #{route[:path].delete_suffix('/:id')}", [])
      end
      sent = examples.select { it[:body].present? }
      ok = sent.select { it[:status].between?(200, 299) }.presence || sent
      if ok.empty?
        fallback = permitted_body(route)
        return fallback && { content: { "application/json" => { schema: schema_for([ fallback ]), example: fallback } } }
      end

      best = ok.max_by { it[:body].to_json.size }
      merged = ok.map { it[:body] }.reduce { |a, b| merge_values(a, b) }
      if ok.any? { it[:multipart] }
        fields = flatten_params(merged)
        schema = { type: "object",
                   properties: fields.to_h { |k, v| [ k, file?(v) ? { type: "string", format: "binary" } : { type: "string", example: v } ] } }
        { content: { "multipart/form-data" => { schema: } } }
      else
        { content: { "application/json" => { schema: schema_for(ok.map { it[:body] }), example: best[:body] } } }
      end
    end

    # No spec sends this body: the keys the action's *_params method allows, read from the controller source
    # (params.expect(key: %i[...]), params.expect(key: policy(X).permitted_attributes), params.permit(:a, :b)).
    def permitted_body(route)
      file = controller_class(route[:controller])&.instance_method(route[:action])&.source_location&.first or return
      source = File.read(file)
      action = source[/def #{route[:action]}\b.*?(?=\n\s*def |\n\s*private)/m].to_s
      method = action[/\b(\w+_params)\b/, 1] or return
      body = source[/def #{method}\b.*?(?=\n\s*def |\n\s*end\s*\n\s*end)/m].to_s
      if (m = body.match(/expect\((\w+): %i\[([^\]]*)\]/))
        { m[1] => m[2].split.to_h { [ it, nil ] } }
      elsif (m = body.match(/expect\((\w+): policy\((\w+)\)\.permitted_attributes/))
        attrs = "#{m[2]}Policy".constantize.new(nil, m[2].constantize).permitted_attributes
        { m[1] => attrs.grep(Symbol).to_h { [ it.to_s, nil ] } }
      elsif (m = body.match(/params\.permit\(([^)]*)\)/))
        m[1].scan(/(?<![\w:]):(\w+)/).flatten.to_h { [ it, nil ] }
      end
    rescue StandardError, NameError
      nil
    end

    def responses(route, examples)
      out = examples.group_by { it[:status] }.sort.to_h do |status, list|
        body = list.map { it[:response] }.compact
        best = status.between?(200, 299) ? body.max_by { it.to_json.size } : body.first
        content = body.any? ? { "application/json" => { schema: schema_for(body), example: best } } : nil
        [ status.to_s, { description: Rack::Utils::HTTP_STATUS_CODES[status].to_s, content: }.compact ]
      end
      if out.keys.none? { it.start_with?("2") }
        out[route[:action] == "destroy" ? "204" : "200"] = { description: route[:action] == "destroy" ? "No Content" : "OK (no recorded example)" }
      end
      out["401"] ||= { "$ref": "#/components/responses/Unauthorized" } if protected?(route)
      out["404"] ||= { "$ref": "#/components/responses/NotFound" } if route[:path].include?(":")
      out["422"] ||= { "$ref": "#/components/responses/Invalid" } unless route[:verb] == "GET"
      out
    end

    # ---- JSON schema from examples ------------------------------------------------------------------------------

    # Schema of one value, from all the examples of it: a key that is ever null is nullable, objects take every key seen.
    def schema_for(values)
      present = values.compact
      schema =
        case present.first
        when nil then { type: "string" }
        when Hash
          keys = present.grep(Hash).flat_map(&:keys).uniq
          { type: "object", properties: keys.to_h { |k| [ k, schema_for(present.grep(Hash).select { it.key?(k) }.map { it[k] }) ] } }
        when Array
          items = present.grep(Array).flatten(1)
          { type: "array", items: items.empty? ? { type: "string" } : schema_for(items) }
        when Numeric
          if present.all?(Integer) then { type: "integer" }
          elsif present.all?(Numeric) then { type: "number" }
          else { type: "string" }
          end
        when true, false then { type: "boolean" }
        when /\A\d{4}-\d{2}-\d{2}\z/ then { type: "string", format: "date" }
        when /\A\d{4}-\d{2}-\d{2}T/ then { type: "string", format: "date-time" }
        else { type: "string" }
        end
      present.size < values.size ? schema.merge(nullable: true) : schema
    end

    def merge_values(a, b)
      if a.is_a?(Hash) && b.is_a?(Hash) then a.merge(b) { |_k, x, y| merge_values(x, y) }
      elsif a.is_a?(Array) && b.is_a?(Array) then a + b
      else a.nil? ? b : a
      end
    end

    def file?(value) = value.is_a?(Hash) && value.key?("__file")

    def recorded
      @recorded ||= [ Recorder::SPECS, Recorder::PROBE ].select(&:exist?).each_with_object(Hash.new { |h, k| h[k] = [] }) do |file, out|
        JSON.parse(file.read).each { |key, list| out[key].concat(list.map(&:symbolize_keys)) }
      end
    end

    # ---- docs ---------------------------------------------------------------------------------------------------

    # Every `VERB /path` written in the docs, with the section (heading + its own text) it sits in.
    def mentions
      @mentions ||= MENUS.keys.flat_map do |file|
        sections(DOCS.join(file).read).flat_map do |section|
          section[:lines].each_with_index.flat_map do |line, i|
            line.scan(MENTION).map { |verb, path| { key: doc_key(verb, path), file:, section:, heading: i.zero? } }
          end
        end
      end
    end

    # The section that names the endpoint in its heading wins; otherwise the first mention (menu files before README).
    def mention_for(route)
      found = mentions.select { it[:key] == doc_key(route[:verb], route[:path]) }
      other = { "PUT" => "PATCH", "PATCH" => "PUT" }[route[:verb]] # Rails routes both to update; the doc may name either
      found = mentions.select { it[:key] == doc_key(other, route[:path]) } if found.empty? && other
      found.find { it[:heading] } || found.first
    end

    def sections(text)
      out = []
      fence = false
      text.each_line do |line|
        fence = !fence if line.start_with?("```")
        if !fence && (m = line.match(/\A(\#{2,4})\s+(.*)/))
          out << { title: m[2].strip, lines: [ line ], body: +"" }
        elsif out.any?
          out.last[:lines] << line
          out.last[:body] << line
        end
      end
      out
    end

    # ---- folders and tags ---------------------------------------------------------------------------------------

    # "Driver App / Sessions", not "Driver App / Driver App Sessions": an app's namespace is its folder already.
    APP_NAMESPACES = %w[portal driver_app].freeze

    def resource_name(controller)
      parts = controller.delete_prefix("api/v1/").split("/")
      parts.shift if parts.size > 1 && APP_NAMESPACES.include?(parts.first)
      parts.map { it.titleize }.join(" ")
    end

    def menu(controller) = FOLDERS.fetch(controller, "Other")

    def folder(controller) = "#{menu(controller)}/#{resource_name(controller)}"

    def tag_name(controller) = "#{menu(controller)} / #{resource_name(controller)}"

    def tags
      routes.map { it[:controller] }.uniq.sort_by { [ ORDER.index(menu(it)), resource_name(it) ] }.map do |controller|
        { name: tag_name(controller), description: class_comment(controller).presence || resource_name(controller) }
      end
    end

    # ---- source comments ----------------------------------------------------------------------------------------

    def controller_class(controller) = "#{controller.camelize}Controller".safe_constantize

    def class_comment(controller)
      file = Rails.root.join("app/controllers/#{controller}_controller.rb")
      return "" unless file.exist?

      file.readlines.take_while { it.start_with?("#") }.map { it.sub(/\A#\s?/, "") }.join.strip
    end

    def method_comment(route)
      @method_comments ||= {}
      @method_comments["#{route[:controller]}##{route[:action]}"] ||= begin
        file, line = controller_class(route[:controller])&.instance_method(route[:action])&.source_location
        if file
          lines = File.readlines(file)[0...(line - 1)]
          lines.reverse.take_while { it.strip.start_with?("#") }.reverse.map { it.strip.sub(/\A#\s?/, "") }.join("\n")
        else
          ""
        end
      rescue NameError
        ""
      end
    end

    # ---- components ---------------------------------------------------------------------------------------------

    def components
      error = ->(code, message) { { error: { code:, message:, details: {} } } }
      response = lambda do |description, code, message|
        { description:, content: { "application/json" => { schema: { "$ref": "#/components/schemas/Error" }, example: error.(code, message) } } }
      end
      {
        securitySchemes: {
          bearerAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT",
                        description: "Convoy OS: data.token from POST /session, sent as Authorization: Bearer <token> (30 days)." },
          portalAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT",
                        description: "Client Portal: data.token from POST /portal/session or /portal/password." },
          driverAuth: { type: "http", scheme: "bearer", bearerFormat: "JWT",
                        description: "Convoy Driver app: data.token from POST /driver/session (mobile + code 123456) or /driver/session/email." }
        },
        schemas: {
          Error: {
            type: "object",
            properties: {
              error: { type: "object", properties: { code: { type: "string" }, message: { type: "string" },
                                                     details: { type: "object", additionalProperties: true } } }
            }
          }
        },
        responses: {
          Unauthorized: response.("Not signed in", "unauthorized", "Sign in to continue"),
          NotFound: response.("Record not found (or in another company)", "not_found", "Not found"),
          Invalid: response.("Validation failed or a business rule was broken", "invalid", "Enter the drop-off point")
        }
      }
    end
  end
end
