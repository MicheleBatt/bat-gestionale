Rails.application.config.after_initialize do
  MetalsValueGetterJob.perform_now
end