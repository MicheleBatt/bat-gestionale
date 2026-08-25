# In produzione il recupero dei valori dei metalli è schedulato da whenever (config/schedule.rb):
# eseguirlo anche all'avvio significherebbe una chiamata all'API esterna a ogni riavvio del container.
if Rails.env.development?
  Rails.application.config.after_initialize do
    MetalsValueGetterJob.perform_now
  end
end
