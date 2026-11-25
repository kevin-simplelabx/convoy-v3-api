require "rails_helper"

# Push token registrations sent at the same moment for one sign-in (start-up and onTokenRefresh, API-ISSUES #21): they
# wait for each other on the sign-in row, so none fails on the unique indexes and one row is left. Real threads need real
# commits, so this file runs outside the test transaction and cleans up after itself.
RSpec.describe "Device registration at the same moment" do
  self.use_transactional_tests = false

  let(:threads) { 4 }

  def at_once(&block)
    barrier = Concurrent::CyclicBarrier.new(threads)
    Array.new(threads) do |i|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          barrier.wait
          block.call(i)
          :ok
        rescue StandardError => e
          e.class
        end
      end
    end.map(&:value)
  end

  describe DriverDevice do
    let!(:account) { DriverAccount.create!(phone: "+6591239876", name: "Race Test") }
    let!(:jwt) { DriverJwt.create!(driver_account: account, jti: SecureRandom.uuid, exp: 1.day.from_now) }

    after do
      DriverJwt.where(id: jwt.id).delete_all
      account.delete
    end

    it "keeps one row per sign-in, with the same or different tokens" do
      expect(at_once { DriverDevice.register!(DriverJwt.find(jwt.id), platform: "android", push_token: "fcm-race") }).to all(eq(:ok))
      expect(at_once { DriverDevice.register!(DriverJwt.find(jwt.id), platform: "android", push_token: "fcm-race-#{it}") }).to all(eq(:ok))
      expect(DriverDevice.where(driver_jwt_id: jwt.id).count).to eq(1)
    end
  end

  describe AppDevice do
    let!(:account) { AppAccount.create!(first_name: "Race", last_name: "Test", terms_accepted_at: Time.current) }
    let!(:jwt) { AppJwt.create!(app_account: account, jti: SecureRandom.uuid, exp: 1.day.from_now) }

    after do
      AppJwt.where(id: jwt.id).delete_all
      account.delete
    end

    it "keeps one row per sign-in, with the same or different tokens" do
      expect(at_once { AppDevice.register!(AppJwt.find(jwt.id), platform: "ios", push_token: "fcm-race") }).to all(eq(:ok))
      expect(at_once { AppDevice.register!(AppJwt.find(jwt.id), platform: "ios", push_token: "fcm-race-#{it}") }).to all(eq(:ok))
      expect(AppDevice.where(app_jwt_id: jwt.id).count).to eq(1)
    end
  end
end
