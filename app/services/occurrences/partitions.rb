# Monthly partitions of trip_occurrences and occurrence_positions (trip_occurrences_y2026m11), both on the run's date.
# Made before rows are written for a month; the daily job makes the next months ahead of time. Idempotent.
module Occurrences
  module Partitions
    module_function

    TABLES = %w[trip_occurrences occurrence_positions].freeze

    def name_for(month, table = "trip_occurrences") = format("%<t>s_y%<y>04dm%<m>02d", t: table, y: month.year, m: month.month)

    def ensure!(from, to)
      month = from.beginning_of_month
      while month <= to
        create(month)
        month = month.next_month
      end
    end

    def create(month)
      @made ||= Set.new
      TABLES.each do |table|
        name = name_for(month, table)
        next if @made.include?(name) && exists?(name)

        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TABLE IF NOT EXISTS #{name} PARTITION OF #{table}
          FOR VALUES FROM ('#{month.iso8601}') TO ('#{month.next_month.iso8601}')
        SQL
        @made << name
      end
    end

    def exists?(name) = ActiveRecord::Base.connection.table_exists?(name)
  end
end
