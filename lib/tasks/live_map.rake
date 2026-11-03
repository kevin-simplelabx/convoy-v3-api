namespace :live_map do
  desc "Sample live data for the Live Map now (not production, except staging with SAMPLE_DATA=1). COMPANY=code to limit, LOOP=seconds to repeat"
  task simulate: :environment do
    scope = ENV["COMPANY"] ? Company.where(code: ENV["COMPANY"]) : Company.all
    loop do
      scope.find_each do |company|
        ActsAsTenant.with_tenant(company) { Time.use_zone(company.timezone) { Telematics::Simulate.call } }
      end
      puts "#{Time.current.strftime('%H:%M:%S')} live data written"
      break unless ENV["LOOP"]

      sleep ENV["LOOP"].to_i.clamp(5, 600)
    end
  end
end
