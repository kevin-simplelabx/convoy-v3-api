# A school with stops and riders for Route Plans specs: n stops (BDSZ03-000k, one point each) whose postal code
# catchment holds `per` riders each (AM and PM).
module SchoolBusHelpers
  def school_with_stops(company, stops: 4, per: 3)
    within_tenant(company) do
      school = School.create!(name: "St. Stephen's School", short_name: "SSS", postal: "455789", lat: 1.3138, lng: 103.9283)
      (1..stops).each do |k|
        stop = Stop.new(code: "BDSZ03-000#{k}", subzone_code: "BDSZ03", name: "Stop #{k}")
        stop.all_points.build(suffix: "A", usage: "both", sizes: %w[S M L], primary: true, lat: 1.32 + (k * 0.004), lng: 103.92 + (k * 0.003))
        stop.save!
        postal = "46010#{k}"
        SchoolStop.create!(school:, stop:, postal_codes: [ postal ])
        per.times { |i| school.riders.create!(rid: "R#{k}#{i}", name: "Rider #{k}#{i}", postal:, lat: 1.32 + (k * 0.004), lng: 103.92 + (k * 0.003), source: "manual") }
      end
      school
    end
  end
end

RSpec.configure { it.include SchoolBusHelpers }
