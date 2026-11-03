# School Bus Stop Assignment: which riders of a school a stop covers, and which PUDO points each rider may use.
module SchoolStops
  module_function

  # Riders of the school today whose home is in a school stop's catchment.
  def riders_covered(school_stop, date: Date.current)
    SchoolRider.of_school_on(school_stop.school, date).select { |r| school_stop.covers?(r.postal, r.lat, r.lng) }
  end

  # "460101, 460102 abc" or an array → [valid 6-digit codes], [invalid tokens].
  def parse_postals(value)
    tokens = (value.is_a?(Array) ? value : value.to_s.split(/[\s,;]+/)).map { it.to_s.strip }.compact_blank
    tokens.partition { it.match?(/\A\d{6}\z/) }.then { |ok, bad| [ ok.uniq, bad.uniq ] }
  end
end
