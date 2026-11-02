class OccurrenceDailyJob < ApplicationJob
  queue_as :default

  def perform = Occurrences::Daily.call
end
