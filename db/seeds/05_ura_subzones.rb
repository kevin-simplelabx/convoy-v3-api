# URA Master Plan 2019 subzones (data.gov.sg, Singapore Open Data Licence), simplified to 5 decimals: they name new
# School Bus stops. Platform data, loaded once.
if UraSubzone.count < 300
  rows = JSON.parse(SeedFiles.open("ura_subzones.json").read).map do |z|
    pts = z["rings"].flatten(1)
    lats = pts.map(&:first)
    lngs = pts.map(&:last)
    z.slice("code", "name", "planning_area", "planning_area_code", "region", "rings")
     .merge("min_lat" => lats.min, "max_lat" => lats.max, "min_lng" => lngs.min, "max_lng" => lngs.max)
  end
  UraSubzone.upsert_all(rows, unique_by: :code)
end
