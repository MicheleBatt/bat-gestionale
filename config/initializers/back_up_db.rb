Rails.application.config.after_initialize do
  BackupDbJob.perform_now
end