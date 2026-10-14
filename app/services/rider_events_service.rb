class RiderEventsService
  def initialize(datasets, manual_riders)
    @datasets = datasets.to_a
    @manual   = manual_riders.to_a
  end

  def call
    events = []
    seen   = Set.new

    @datasets.each_with_index do |ds, i|
      add(events, seen, ds.effective_from.iso8601, "list", nil, ds.file_name, "")

      prev_map = i > 0 ? @datasets[i - 1].rows.index_by { |r| r["rid"] } : nil
      cur_rids = ds.rows.map { |r| r["rid"] }.to_set

      ds.rows.each do |r|
        late = r["start"].present? && r["start"] > ds.effective_from.iso8601

        if (prev_map && !prev_map.key?(r["rid"])) || late
          add(events, seen, late ? r["start"] : ds.effective_from.iso8601, "join", r["rid"], r["name"], svc(r))
        elsif prev_map && (prev = prev_map[r["rid"]]) && svc(prev) != svc(r)
          add(events, seen, ds.effective_from.iso8601, "change", r["rid"], r["name"], svc(r))
        end

        add(events, seen, r["end"], "leave", r["rid"], r["name"], svc(r)) if r["end"].present?
      end

      prev_map&.each do |rid, r|
        add(events, seen, ds.effective_from.iso8601, "leave", rid, r["name"], svc(r)) unless cur_rids.include?(rid)
      end
    end

    @manual.each do |r|
      add(events, seen, r.start_date&.iso8601, "join",  r.rid, r.name, "") if r.start_date
      add(events, seen, r.end_date&.iso8601,   "leave", r.rid, r.name, "") if r.end_date
    end

    events.sort_by { |e| e[:date] }
  end

  private

  def add(events, seen, date, kind, rid, name, svc_str)
    return unless date
    key = "#{date}#{kind}#{rid || name}"
    return if seen.include?(key)
    seen.add(key)
    events << { date: date, kind: kind, rid: rid, name: name, svc: svc_str }
  end

  def svc(row)
    parts = []
    parts << "AM"  if row["am"] != false
    parts << "PM"  if row["pm"] != false
    parts << "CCA" if row["cca"].present?
    parts.empty? ? "No service" : parts.join(" + ")
  end
end
