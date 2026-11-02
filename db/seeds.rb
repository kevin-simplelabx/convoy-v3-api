# Sample data, idempotent: every file in db/seeds runs in name order and can be re-run safely.
#   bin/rails db:seed            all
#   SEED=10_fleet bin/rails db:seed   one file
files = Dir[Rails.root.join("db/seeds/*.rb")].sort
files = files.select { |f| File.basename(f, ".rb") == ENV["SEED"] } if ENV["SEED"].present?

files.each do |file|
  puts "Seeding #{File.basename(file)}"
  load file
end
