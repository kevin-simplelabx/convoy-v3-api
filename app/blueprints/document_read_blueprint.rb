class DocumentReadBlueprint < ApplicationBlueprint
  fields :kind, :status, :error, :created_at, :finished_at
  field(:result) { |r| r.done? ? r.result : nil }
  field(:file) { |r| r.file_info(:file) }
end
