# School Levels page: the saved levels with today's rider counts — or, before any are saved, the ones suggested from rider
# data (the whole section when a rider's grade matches one of its levels, else the grades found) — the grades in rider
# data that are not levels, and the "What the School Offers" sections.
module SchoolLevels
  class Page
    def initialize(school, date: Date.current)
      @school = school
      @counts = SchoolRider.of_school_on(school, date).where.not(grade: [ nil, "" ]).group(Arel.sql("lower(grade)")).count
    end

    def call
      saved = @school.levels.to_a
      list = saved.any? ? saved.map { |l| row(l.name, l.section, l.final) } : suggested
      names = list.to_set { it[:name].downcase }
      lock = SchoolSetup.find(@school, nil, :levels)
      {
        saved: saved.any?, levels: list, locked: lock && { at: lock.locked_at, by: lock.locked_by&.name },
        unknown: @counts.reject { |g, _| names.include?(g) }.map { |g, n| { grade: grade_name(g), riders: n } },
        sections: SchoolLevel::SECTIONS.map { |k, (name, group, text, defaults)| { key: k, name:, group:, description: text, levels: defaults } }
      }
    end

    private

    def row(name, section, final) = { name:, section:, final:, riders: @counts[name.downcase].to_i }

    def suggested
      list = SchoolLevel::SECTIONS.flat_map do |k, (*, defaults)|
        defaults.any? { @counts.key?(it.downcase) } ? defaults.map { row(it, k, false) } : []
      end
      list = @counts.keys.sort_by { |g| g.scan(/\d+|\D+/).map { it.match?(/\d/) ? it.to_i : it } }.map { row(grade_name(it), "custom", false) } if list.empty?
      list.last[:final] = true if list.any?
      list
    end

    def grade_name(lower) = SchoolRider.where(school: @school).where("lower(grade) = ?", lower).pick(:grade) || lower
  end
end
