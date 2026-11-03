# Copy AY X Sessions: another year's sessions as a draft for this year (days that are no longer operating days dropped).
module BusSessions
  class Copy
    def self.call(from, to)
      from.bus_sessions.includes(:variants).map do |s|
        BusSessionBlueprint.render_as_hash(s).except(:id).merge(days: s.days & to.operating_days)
                           .tap { |h| h[:variants] = h[:variants].map { |v| v.merge(days: v[:days] & to.operating_days) } }
      end
    end
  end
end
