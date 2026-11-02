# Document numbers: the type's prefix (Finance Settings), the year, then a running number that restarts each year:
# INV-2026-000001. One counter per company, type and year (CompanySequence), so numbers never repeat.
module Finance
  module Numbering
    module_function

    def next!(type, date: Date.current, settings: FinanceSetting.current)
      n = CompanySequence.next!("doc:#{type}:#{date.year}")
      format("%<prefix>s-%<year>d-%<n>06d", prefix: settings.prefix(type), year: date.year, n:)
    end
  end
end
