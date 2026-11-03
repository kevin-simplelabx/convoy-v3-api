# School Levels › Save & Lock: the whole list in order (names required and unique, ignoring case; at least one).
module SchoolLevels
  class Save < ApplicationService
    def initialize(school, levels, user:)
      @school = school
      @levels = Array(levels)
      @user = user
    end

    def call
      SchoolSetup.ensure_unlocked!(school: @school, section: :levels)
      raise Error, "Add at least one level" if @levels.empty?

      names = @levels.map { it[:name].to_s.strip }
      raise Error, "Every level needs a name" if names.any?(&:empty?)

      dup = names.group_by(&:downcase).find { |_, v| v.size > 1 }
      raise Error, "#{dup.last.first} is listed twice" if dup

      SchoolLevel.transaction do
        @school.levels.delete_all
        @levels.each.with_index(1) do |l, i|
          @school.levels.create!(position: i, name: names[i - 1], section: l[:section].presence || "custom", final: ActiveModel::Type::Boolean.new.cast(l[:final]) || false)
        end
        SchoolSetup.lock!(school: @school, section: :levels, user: @user)
      end
    end
  end
end
