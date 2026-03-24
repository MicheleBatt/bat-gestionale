Rails.application.config.after_initialize do
  begin
    GetRealTimeMetalsValueCommand.call
  rescue StandardError => e
    Rails.logger.warn("Failed to fetch metal values at boot: #{e.message}")
  end
end