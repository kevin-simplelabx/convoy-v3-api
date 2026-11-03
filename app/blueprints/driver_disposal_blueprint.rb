# A disposal's record in the Driver app (and Trip History): the start, the block clock, runs, extensions and the end.
# Render a decorated OccurrenceDisposal.
class DriverDisposalBlueprint < Blueprinter::Base
  fields :block_starts_at, :started_at, :early_start, :late_minutes, :start_odometer, :extension_minutes, :ended_at, :end_odometer,
         :released_by, :km

  field(:start_photo) { |d| d.start_photo_info }
  field(:end_photo) { |d| d.end_photo_info }
  field(:release_signature) { |d| d.release_signature_info }
  field(:clock) { |d| d.figures }
  field(:runs) do |d|
    d.runs.map do |r|
      { id: r.id, started_at: r.started_at, ended_at: r.ended_at, from_road: r.from_road, to_road: r.to_road, pax: r.pax,
        minutes: (((r.ended_at || Time.current) - r.started_at) / 60).floor }
    end
  end
  field(:extensions) do |d|
    d.extensions.map do |e|
      { at: e.at, from_minutes: e.from_minutes, to_minutes: e.to_minutes, signed_by: e.signed_by, operations_told: e.operations_told,
        signature: e.signature.present? ? OccurrenceDisposalExtensionDecorator.new(e).file_info(:signature) : nil }
    end
  end
end
