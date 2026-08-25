# Numio — deploy su Raspberry Pi

Procedura completa per portare l'applicazione dalla macchina di sviluppo al Raspberry Pi,
esposta su internet tramite Cloudflare Tunnel e protetta da Cloudflare Access.

**Architettura:**

```
utente → Cloudflare (TLS + Access: whitelist email)
           ↓ tunnel in uscita, nessuna porta aperta sul router
       cloudflared (servizio sull'host)
           ↓ http://127.0.0.1:3000
       docker compose ─┬─ app (Rails + Puma)
                       └─ db  (Postgres 16)
           ↓
       SSD esterno USB: dati Postgres + dump di backup
```

---

## 1. Preparazione della microSD

Da questa macchina, con **Raspberry Pi Imager**:

- Sistema operativo: **Raspberry Pi OS Lite (64-bit)** — senza desktop.
- Nelle opzioni avanzate (icona ingranaggio) imposta:
  - hostname: `numio`
  - utente e password
  - **SSH abilitato** con autenticazione a chiave pubblica
  - locale/timezone: `Europe/Rome`

Al primo avvio il Pi è già raggiungibile via rete: non servono monitor né tastiera.

```bash
ssh <utente>@numio.local
```

## 2. Sistema di base

```bash
sudo apt update && sudo apt full-upgrade -y
sudo timedatectl set-timezone Europe/Rome
sudo apt install -y git rclone
```

## 3. Montaggio dell'SSD

Collega l'SSD a una porta **USB 3.0** (quelle blu) e individua il disco:

```bash
lsblk -f
```

Formattalo (⚠️ cancella il contenuto del disco indicato) e montalo in modo permanente:

```bash
sudo mkfs.ext4 -L numio /dev/sdX1          # sostituisci sdX1 con il device reale
sudo mkdir -p /mnt/ssd
echo "LABEL=numio /mnt/ssd ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab
sudo mount -a
```

Prepara le cartelle dei dati. Il container dell'app gira come utente non privilegiato `rails`
(uid 1000), quindi la cartella dei backup deve appartenergli:

```bash
sudo mkdir -p /mnt/ssd/numio/pgdata /mnt/ssd/numio/db_backup
sudo chown -R 1000:1000 /mnt/ssd/numio/db_backup
```

## 4. Docker

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Esci e rientra via SSH perché il nuovo gruppo abbia effetto.

## 5. Codice e configurazione

```bash
git clone <url-del-repository> ~/numio
cd ~/numio
cp .env.production.example .env.production
chmod 600 .env.production
nano .env.production     # compila APP_HOST, DATA_DIR, credenziali DB, RAILS_MASTER_KEY
```

`RAILS_MASTER_KEY` è il contenuto di `config/master.key` sulla macchina di sviluppo: quel file
non è versionato, quindi va copiato a mano.

## 6. Avvio

Le immagini si costruiscono direttamente sul Pi, che è arm64:

```bash
docker compose -f docker-compose.production.yml --env-file .env.production up -d --build
docker compose -f docker-compose.production.yml --env-file .env.production logs -f app
```

La prima compilazione richiede diversi minuti. L'entrypoint esegue `db:prepare`, quindi crea
il database e applica le migrazioni al primo avvio.

Verifica:

```bash
curl -I http://127.0.0.1:3000/up
```

## 7. Migrazione dei dati esistenti

Sulla macchina di sviluppo:

```bash
pg_dump -F c batgestionale_development > numio_dump.pgc
scp numio_dump.pgc <utente>@numio.local:~/
```

Sul Pi:

```bash
docker compose -f docker-compose.production.yml --env-file .env.production cp \
  ~/numio_dump.pgc db:/tmp/dump.pgc
docker compose -f docker-compose.production.yml --env-file .env.production exec db \
  pg_restore --clean --no-owner --no-acl -U <DATABASE_USER> -d <DATABASE> /tmp/dump.pgc
```

## 8. Job schedulati

Nel container non gira cron, quindi `config/schedule.rb` (whenever) non viene usato in produzione:
i due job sono lanciati dal cron dell'host. `crontab -e`:

```cron
0 2 * * * cd /home/<utente>/numio && docker compose -f docker-compose.production.yml --env-file .env.production exec -T app bin/rails runner 'BackupDbJob.perform_now' >> /var/log/numio-cron.log 2>&1
0 8 * * * cd /home/<utente>/numio && docker compose -f docker-compose.production.yml --env-file .env.production exec -T app bin/rails runner 'MetalsValueGetterJob.perform_now' >> /var/log/numio-cron.log 2>&1
```

## 9. Backup fuori dalla macchina

Il dump giornaliero finisce in `/mnt/ssd/numio/db_backup`, ma sulla stessa macchina: se il Pi si
guasta, spariscono anche i backup. Configura una destinazione remota con `rclone config`
(Google Drive, Dropbox, un altro server) e aggiungi al crontab:

```cron
30 2 * * * rclone copy /mnt/ssd/numio/db_backup <remote>:numio-backup >> /var/log/numio-cron.log 2>&1
```

## 10. Cloudflare Tunnel e Access

Sul pannello Cloudflare, con il dominio `numio.eu` già aggiunto come zona:

1. **Zero Trust → Networks → Tunnels**: crea un tunnel, installa `cloudflared` sul Pi con il
   comando che Cloudflare fornisce (si registra come servizio di sistema e riparte da solo).
2. Configura la rotta pubblica: hostname `numio.eu` → servizio `http://127.0.0.1:3000`.
3. **Zero Trust → Access → Applications**: crea un'applicazione self-hosted sul dominio e una
   policy di tipo *Allow* che elenca le email autorizzate. Imposta la durata della sessione
   (per esempio 30 giorni) per non richiedere il codice a ogni accesso.

Da questo momento l'app è raggiungibile in HTTPS da qualsiasi rete, solo per chi è in whitelist.

## 11. Aggiornamenti futuri

```bash
cd ~/numio
git pull
docker compose -f docker-compose.production.yml --env-file .env.production up -d --build
```

Gli utenti non devono fare nulla: al successivo accesso trovano la versione aggiornata.
