# Save Calendar (Terms & Semesters): operating days, semesters (2) or terms (3 / 4) with their dates in order inside the
# year, CCA / ASA periods (the terms' dates, or their own), then locks the calendar. School Bus runs of the school follow.
module AcademicYears
  class SaveCalendar < ApplicationService
    def initialize(year, params, user:)
      @year = year
      @params = params
      @user = user
    end

    def call
      SchoolSetup.ensure_unlocked!(school: @year.school, year: @year, section: :calendar)
      AcademicYear.transaction do
        @year.assign_attributes(@params.slice(:operating_days, :structure, :period_count, :cca_same_as_terms))
        @year.operating_days = Array(@year.operating_days).map(&:to_i).select { it.between?(1, 7) }.uniq.sort
        rows = Array(@params[:terms]).first(@year.period_count)
        check!(rows)
        @year.save!
        @year.terms.delete_all
        rows.each.with_index(1) do |t, i|
          @year.terms.create!(position: i, starts_on: t[:starts_on], ends_on: t[:ends_on],
                              cca_starts_on: @year.cca_same_as_terms ? nil : t[:cca_starts_on], cca_ends_on: @year.cca_same_as_terms ? nil : t[:cca_ends_on])
        end
        SchoolSetup.lock!(school: @year.school, year: @year, section: :calendar, user: @user)
      end
      AcademicYears.resync(@year.school)
      @year.reload
    end

    private

    def check!(rows)
      raise Error, "Pick at least one operating day" if @year.operating_days.empty?
      raise Error, @year.errors.full_messages.to_sentence unless @year.valid?
      raise Error, "Enter #{@year.period_count} #{@year.period_label.downcase.pluralize}" if rows.size < @year.period_count

      last_end = nil
      rows.each.with_index(1) do |t, i|
        name = "#{@year.period_label} #{i}"
        from = date(t[:starts_on], name)
        to = date(t[:ends_on], name)
        raise Error, "#{name} needs a start and an end" unless from && to
        raise Error, "#{name} ends before it starts" if to < from
        raise Error, "#{name} must start after #{@year.period_label} #{i - 1} ends" if last_end && from <= last_end
        raise Error, "#{name} must be inside AY #{@year.key} (#{span})" if from < @year.starts_on || to > @year.ends_on

        cca(t, name) unless @year.cca_same_as_terms
        last_end = to
      end
    end

    def cca(t, name)
      from = date(t[:cca_starts_on], "#{name} CCA")
      to = date(t[:cca_ends_on], "#{name} CCA")
      raise Error, "#{name} CCA / ASA needs a start and an end" unless from && to
      raise Error, "#{name} CCA / ASA ends before it starts" if to < from
      raise Error, "#{name} CCA / ASA must be inside AY #{@year.key} (#{span})" if from < @year.starts_on || to > @year.ends_on
    end

    def span = "#{@year.starts_on.strftime('%-d %b %Y')} to #{@year.ends_on.strftime('%-d %b %Y')}"

    def date(value, name)
      value.present? ? Date.iso8601(value.to_s) : nil
    rescue Date::Error
      raise Error, "#{name}: dates must look like 2026-01-02"
    end
  end
end
