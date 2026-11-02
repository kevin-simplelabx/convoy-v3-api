namespace :occurrences do
  desc "Daily upkeep now: partitions, push the horizon, complete ended runs"
  task daily: :environment do
    Occurrences::Daily.call
  end

  desc "Sync every kept trip of every company (COMPANY=code to limit)"
  task sync: :environment do
    scope = ENV["COMPANY"] ? Company.where(code: ENV["COMPANY"]) : Company.all
    scope.find_each do |company|
      ActsAsTenant.with_tenant(company) do
        Time.use_zone(company.timezone) do
          changed = Occurrences::Sync.call(trips: Trip.with_discarded.pluck(:id), routes: SchoolRoute.pluck(:id))
          puts "#{company.code}: #{changed.size} rows changed"
        end
      end
    end
  end

  desc "Compare stored future runs with what the generator says (reports differences, changes nothing)"
  task verify: :environment do
    Company.find_each do |company|
      ActsAsTenant.with_tenant(company) do
        Time.use_zone(company.timezone) do
          diff = Occurrences::Verify.call
          puts "#{company.code}: #{diff.empty? ? 'all match' : "#{diff.size} differences"}"
          diff.first(20).each { |d| puts "  #{d}" }
        end
      end
    end
  end
end
