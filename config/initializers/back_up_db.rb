# In produzione il backup è schedulato da whenever (config/schedule.rb): eseguirlo anche
# all'avvio significherebbe un pg_dump a ogni riavvio del container.
if Rails.env.development?
  Rails.application.config.after_initialize do
    BackupDbJob.perform_now
  end
end
