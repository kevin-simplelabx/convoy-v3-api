# A rider list of a school (Rider Data tab) and its state on a date (in_use / scheduled / replaced).
class RiderDatasetBlueprint < ApplicationBlueprint
  fields :effective_from, :file_name, :riders_count, :unlocated_count, :status, :created_at
  field(:uploaded_by) { |d| d.uploaded_by&.name }
  field(:file) { |d| d.file_download }
  field(:state) { |d, o| o[:date] && d.state_on(o[:date], o[:in_use]) }
end
