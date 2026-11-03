# One session's Route Labels with a preview of the first three names.
class SchoolRouteLabelBlueprint < ApplicationBlueprint
  identifier :session
  fields :prefix, :start, :digits, :suffix
  field(:preview) { |l| (1..3).map { l.label(it) } }
end
