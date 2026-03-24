class BackupDbJob < ApplicationJob
  queue_as :default

  def perform
    BackupDbCommand.call
  end
end