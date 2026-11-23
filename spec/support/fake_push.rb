# A stand-in for Firebase Cloud Messaging: keeps every message; tokens in `gone` answer "unregistered", `fail` raises.
class FakePush
  attr_reader :sent, :gone
  attr_accessor :fail

  def initialize
    @sent = []
    @gone = []
  end

  def deliver(token:, title:, body:, data:)
    raise Push::Error, "FCM 503" if fail
    return :unregistered if gone.include?(token)

    @sent << { token:, title:, body:, data: }
    :sent
  end
end

module FakePushHelper
  def fake_push = @fake_push ||= FakePush.new
end

RSpec.configure do |config|
  config.include FakePushHelper
  config.before { Push.client = fake_push }
  config.after { Push.client = nil }
end
