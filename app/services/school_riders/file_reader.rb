# Reads a rider list (CSV or XLSX) as the prototype does: columns found by name in any order (student_id or "Student
# ID" or "ID"…), one rider per row. Rows with a problem are skipped and reported by line; a student ID used twice
# keeps the first row.
module SchoolRiders
  class FileReader
    COLUMNS = {
      rid: [ "student id", "id", "studentid" ], name: [ "student name", "name", "studentname", "name of child" ],
      gender: [ "gender", "sex" ], grade: [ "grade class", "grade/class", "grade", "class", "level", "gradeclass" ],
      address: [ "address", "home address" ], postal: [ "postal code", "postal", "postcode", "postalcode" ],
      am: [ "am", "am pickup", "morning" ], pm: [ "pm", "pm dropoff", "afternoon" ], cca: [ "cca days", "cca", "asa", "asa/cca" ],
      starts_on: [ "start date", "start", "from" ], ends_on: [ "end date", "end", "to" ], parent_name: [ "parent name", "parent", "guardian" ],
      parent_contact: [ "parent contact", "contact", "phone", "parent phone" ], remarks: [ "remarks", "remark", "notes" ]
    }.freeze
    REQUIRED = { name: "Student Name", address: "Address", postal: "Postal Code" }.freeze
    YES = /\A(y|yes|true|1|x|✓)\z/i

    Result = Data.define(:rows, :errors)

    def self.call(path, ext) = new(path, ext).call

    def initialize(path, ext)
      @path = path
      @ext = ext.to_s.delete(".").downcase
    end

    def call
      table = read
      return Result.new([], [ { line: 0, message: "The file is empty" } ]) if table.empty?

      map = header_map(table.first)
      missing = REQUIRED.reject { |k, _| map.key?(k) }.map { |_, label| { line: 1, message: %(Missing column "#{label}") } }
      return Result.new([], missing) if missing.any?

      rows = []
      errors = []
      table.drop(1).each.with_index(2) do |cells, line|
        row, problems = parse(cells, map, line)
        problems.any? ? errors << { line:, message: "#{row[:name].presence || "Row #{line}"}: #{problems.join(', ')}" } : rows << row
      end
      seen = {}
      rows = rows.reject do |r|
        dup = seen.key?(r[:rid])
        errors << { line: r[:line], message: "Student ID #{r[:rid]} appears more than once (row skipped)" } if dup
        seen[r[:rid]] = true
        dup
      end
      Result.new(rows, errors)
    end

    private

    def read
      sheet = Roo::Spreadsheet.open(@path, extension: @ext.to_sym).sheet(0)
      (sheet.first_row..sheet.last_row).map { |i| sheet.row(i).map { cell(it) } }.reject { |r| r.all?(&:blank?) }
    rescue StandardError => e
      raise ApplicationService::Error, "The file could not be read (#{e.message.truncate(80)}). Upload a CSV or XLSX"
    end

    def cell(v)
      v.is_a?(Date) ? v.iso8601 : v.to_s.strip.delete_prefix("﻿")
    end

    def header_map(head)
      names = head.map { it.to_s.downcase.tr("_", " ").squeeze(" ").strip }
      COLUMNS.each_with_object({}) do |(key, aliases), map|
        i = names.index { |h| aliases.include?(h) }
        map[key] = i if i
      end
    end

    def parse(cells, map, line)
      get = ->(k) { map[k] ? cells[map[k]].to_s.strip : "" }
      postal = get.(:postal).gsub(/\D/, "").rjust(6, "0")
      row = {
        line:, rid: get.(:rid).presence || "S-#{line.to_s.rjust(4, '0')}", name: get.(:name), gender: get.(:gender).presence,
        grade: get.(:grade).presence, address: get.(:address), postal:,
        am: map[:am] ? get.(:am).match?(YES) : true, pm: map[:pm] ? get.(:pm).match?(YES) : true,
        cca_days: SchoolRider.parse_days(get.(:cca)), starts_on: date(get.(:starts_on)), ends_on: date(get.(:ends_on)),
        parent_name: get.(:parent_name).presence, parent_contact: get.(:parent_contact).presence, remarks: get.(:remarks).presence
      }
      problems = []
      problems << "no student name" if row[:name].blank?
      problems << "postal code must be 6 digits" if postal == "000000" || postal.length != 6
      problems << "CCA days must be days like Mon;Wed" if row[:cca_days].nil?
      problems << "dates must be YYYY-MM-DD or DD/MM/YYYY" if row[:starts_on] == :bad || row[:ends_on] == :bad
      if row[:starts_on].is_a?(Date) && row[:ends_on].is_a?(Date) && row[:ends_on] < row[:starts_on]
        problems << "end date is before start date"
      end
      problems << "pick at least one of AM, PM or CCA" unless row[:am] || row[:pm] || row[:cca_days].present?
      [ row, problems ]
    end

    def date(text)
      return nil if text.blank?

      if (m = text.match(/\A(\d{4})-(\d{1,2})-(\d{1,2})\z/)) then Date.new(m[1].to_i, m[2].to_i, m[3].to_i)
      elsif (m = text.match(%r{\A(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\z})) then Date.new(m[3].to_i, m[2].to_i, m[1].to_i)
      else :bad
      end
    rescue Date::Error
      :bad
    end
  end
end
