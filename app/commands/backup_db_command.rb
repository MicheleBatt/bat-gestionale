include ApplicationHelper

module BackupDbCommand

  def self.call
    puts "[#{Time.now}] Backup DB job started"

    # Creo il backup del db e lo salvo in una cartella locale della macchina su cui gira l'applicazione
    folder_path = "#{Rails.env.development? ? '' : '/var/www/'}db_backup"
    Dir.mkdir(folder_path) unless Dir.exist?(folder_path)
    folder_path += "/#{parse_date(Date.today, '%Y%m%d')}"
    Dir.mkdir(folder_path) unless Dir.exist?(folder_path)
    db_backup_file_name = "db_backup_#{Rails.env}.tar"
    database = Rails.env.development? ? 'batgestionale_development' : ENV['DATABASE']
    cmd = "#{Rails.env.development? ? '' : 'PGPASSWORD=' + ENV['DATABASE_PWD']} pg_dump -F t #{database} > #{folder_path}/#{db_backup_file_name}"

    # Eseguo il comando e verifico se la sua eseuzione sia andata a buon fine. Se si, proseguo. Se no, interrompo
    # l'esecuzione del command lanciando un'eccezione
    success = system(cmd)
    unless success
      error_message = "pg_dump fallito: il backup del database non è stato completato"
      Rails.logger.warn error_message
      raise error_message
    end

    puts "[#{Time.now}] Backup DB job ended"


    # COMANDO PER EFFETTUARE IL RESTORE DEL DB A PARTIRE DA UN DUMP PRECEDENTE:
    #
    # pg_restore -C -d nome_del_database path/dove/si/trova/il/backup/del/db/db_backup_#{Rails.env}.tar
    #
    # L'opzione -C serve per specificare la creazione del db e dello schema prima di fare il restore; nel caso il
    # database esista già, omettere -C e usare direttamente -d con il nome del database di destinazione.
    #
    # Se invece si volessse fare un restore pulito (cancellando prima tutti gli oggetti eventualmente presenti nel db
    # e ricreando tutto ex-novo), lanciare questo comando:
    #
    # pg_restore --clean --no-owner --no-acl -d nome_del_database path/dove/si/trova/il/backup/del/db/db_backup_#{Rails.env}.tar
    #
    # dove:
    # --clean — droppa gli oggetti esistenti prima di ricrearli
    # --no-owner — non tenta di impostare l'ownership originale
    # --no-acl — ignora i permessi (GRANT/REVOKE)
  end
end