# Rider changes of a school for the "Plan For" calendar (port of the prototype's riderEvents): each rider list starts on
# its date (list); against the list before it, a rider new to the list or starting later joins, one whose service
# (AM + PM + CCA) changed changes, one gone from it leaves; a rider's end date is a leave. Riders added by hand join on
# their start and leave on their end. One event per date, kind and rider; by date.
class RiderEvents
  KINDS = %w[list join change leave].freeze
  FIELDS = %i[rid name am pm cca_days starts_on ends_on rider_dataset_id].freeze

  def initialize(school)
    @school = school
  end

  def call
    @out = []
    @seen = Set.new
    rows = @school.riders.pluck(*FIELDS).map { FIELDS.zip(it).to_h }
    by_list = rows.group_by { it[:rider_dataset_id] }
    prev = nil
    @school.rider_datasets.each do |d|
      add(d.effective_from, "list", name: d.file_name)
      cur = by_list[d.id] || []
      cur.each do |r|
        before = prev&.dig(r[:rid])
        late = r[:starts_on] && r[:starts_on] > d.effective_from
        if (prev && before.nil?) || late then add(late ? r[:starts_on] : d.effective_from, "join", r)
        elsif before && service(before) != service(r) then add(d.effective_from, "change", r)
        end
        add(r[:ends_on], "leave", r) if r[:ends_on]
      end
      ids = cur.to_set { it[:rid] }
      prev&.each_value { |r| add(d.effective_from, "leave", r) unless ids.include?(r[:rid]) }
      prev = cur.index_by { it[:rid] }
    end
    (by_list[nil] || []).each do |r|
      add(r[:starts_on], "join", r) if r[:starts_on]
      add(r[:ends_on], "leave", r) if r[:ends_on]
    end
    @out.sort_by { [ it[:date], KINDS.index(it[:kind]) ] }
  end

  # Changes (not new lists) after a day and up to 30 days on: the badge on the Plan For date.
  def self.soon(events, date) = events.count { it[:kind] != "list" && it[:date] > date && it[:date] <= date + 30 }

  private

  def service(r) = [ ("AM" if r[:am] != false), ("PM" if r[:pm] != false), ("CCA" if Array(r[:cca_days]).any?) ].compact.join(" + ").presence || "No service"

  def add(date, kind, rider = nil, name: nil)
    return unless date

    key = [ date, kind, rider ? rider[:rid] : name ]
    return if @seen.include?(key)

    @seen << key
    @out << { date:, kind:, rid: rider&.dig(:rid), name: rider ? rider[:name] : name, service: rider ? service(rider) : nil }
  end
end
