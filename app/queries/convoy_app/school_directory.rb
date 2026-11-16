# The schools a parent can pick for a child: every school Convoy runs buses for at an active transport company, once per
# name (the same school may be served by two companies), with the levels it offers. "Other" is not a row: the app sends
# school_name instead. Reads across companies on purpose: this is the platform directory, not a company's data.
module ConvoyApp
  class SchoolDirectory
    DEFAULT_LEVELS = (1..6).map { "Primary #{it}" }.freeze

    def self.call = new.call

    def self.find(id) = new.rows.find { it[:id] == id.to_i }

    def call = rows.map { it.slice(:id, :name, :levels) }

    # One row per school name: the oldest school of that name, with its levels (DEFAULT_LEVELS when it set none).
    def rows
      @rows ||= ActsAsTenant.without_tenant do
        schools = School.where(company_id: Company.active.select(:id)).order(:id).to_a
        levels = SchoolLevel.where(school_id: schools.map(&:id)).order(:position).group_by(&:school_id)
        schools.uniq { it.name.downcase }.sort_by { it.name.downcase }.map do |s|
          names = levels[s.id]&.map(&:name).presence || DEFAULT_LEVELS
          { id: s.id, name: s.name, levels: names }
        end
      end
    end
  end
end
