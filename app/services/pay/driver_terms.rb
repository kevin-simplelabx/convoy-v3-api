# What a driver is paid on, day by day: the pay scheme (their assignment that day; with no assignments at all, the
# default scheme; with assignments that don't cover the day, none) and the vehicle type assigned (nil = the type of
# the bus of each job). Built once for a range, then asked per date.
module Pay
  class DriverTerms
    def initialize(driver, from:, to:)
      @schemes = driver.pay_schemes.where(starts_on: ..to).where("ends_on IS NULL OR ends_on >= ?", from).includes(:pay_scheme).to_a
      @any_scheme = @schemes.any? || driver.pay_schemes.exists?
      @types = driver.pay_vehicle_types.where(starts_on: ..to).where("ends_on IS NULL OR ends_on >= ?", from).to_a
      @default = PayScheme.kept.find_by(is_default: true) unless @any_scheme
    end

    def scheme_on(date)
      return @default unless @any_scheme

      pick(@schemes, date)&.pay_scheme&.then { |s| s.discarded? ? nil : s }
    end

    def vehicle_type_id_on(date) = pick(@types, date)&.vehicle_type_id

    private

    def pick(rows, date) = rows.select { |r| r.starts_on <= date && (r.ends_on.nil? || r.ends_on >= date) }.max_by(&:starts_on)
  end
end
