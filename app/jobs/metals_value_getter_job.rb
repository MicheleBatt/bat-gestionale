class MetalsValueGetterJob < ApplicationJob
  queue_as :default

  def perform
    begin
      GetRealTimeMetalsValueCommand.call
    rescue StandardError => e
      Rails.logger.warn("Failed to fetch metal values: #{e.message}")
    end
  end
end