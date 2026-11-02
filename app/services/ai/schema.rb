# Builds strict JSON schemas for structured outputs: every key required, no extra keys.
module Ai
  module Schema
    module_function

    # object(plate: :string, items: array(object(...)))
    def object(**props)
      {
        type: "object",
        properties: props.transform_values { |v| v.is_a?(Hash) ? v : { type: v.to_s } },
        required: props.keys.map(&:to_s),
        additionalProperties: false
      }
    end

    def array(items) = { type: "array", items: }
    def enum(*values) = { type: "string", enum: values.map(&:to_s) }
  end
end
