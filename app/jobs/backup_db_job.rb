class BackupDbJob < ApplicationJob
  queue_as :default

  def perform
    begin
      BackupDbCommand.call
    rescue StandardError => e
      Rails.logger.warn("Failed to execute backup db: #{e.message}")
    end
  end
end