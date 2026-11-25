#!/usr/bin/env bash
set -euo pipefail
umask 077

# Run only on the intended Ubuntu VPS, using an already verified application JAR.
api_domain=${1:?Supply the public API hostname}
web_origin=${2:?Supply the HTTPS web origin}
database_mode=${3:-existing}
bundle=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
fail() { printf '%s\n' "$*" >&2; exit 1; }
[[ $EUID -eq 0 ]] || fail 'Run with sudo.'
[[ $api_domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ && $api_domain == *.* ]] || fail 'Invalid API hostname.'
[[ $web_origin =~ ^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$ ]] || fail 'Use an HTTPS web origin without a trailing slash.'
[[ $database_mode == existing || $database_mode == new ]] || fail 'Database mode must be existing or new.'
[[ -s "$bundle/backend.jar" ]] || fail 'Missing backend.jar; build and verify locally first.'
source /etc/os-release
[[ $ID == ubuntu && $VERSION_ID == 24.04 ]] || fail 'This installer targets Ubuntu Server 24.04 LTS.'

if [[ $database_mode == existing && ! -s /etc/thoxay/backend.env && ! -s "$bundle/backend.env" ]]; then
    fail 'Existing database mode requires backend.env with DB_URL, DB_USERNAME, DB_PASSWORD and JWT_SECRET.'
fi
if [[ -s "$bundle/backend.env" ]]; then
    for setting in DB_URL DB_USERNAME DB_PASSWORD JWT_SECRET; do
        grep -Eq "^${setting}=.+" "$bundle/backend.env" || fail "Missing ${setting} in backend.env."
    done
fi
if [[ $database_mode == new && -e /etc/thoxay/backend.env && ! -e /etc/thoxay/postgres.env ]]; then
    fail 'An external database is already configured. Refusing to replace it with an empty database.'
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y openjdk-17-jre-headless nginx certbot python3-certbot-nginx curl openssl
id thoxay >/dev/null 2>&1 || useradd --system --home-dir /var/lib/thoxay --shell /usr/sbin/nologin thoxay
install -d -m 700 /etc/thoxay
install -d -m 755 /opt/thoxay /opt/thoxay/releases
install -d -m 700 -o thoxay -g thoxay /var/lib/thoxay

# Swap helps absorb transient peaks; it does not replace RAM.
if [[ ! -f /var/lib/thoxay.swap && $(swapon --noheadings --show | wc -l) -eq 0 ]]; then
    fallocate -l 2G /var/lib/thoxay.swap
    chmod 600 /var/lib/thoxay.swap
    mkswap /var/lib/thoxay.swap >/dev/null
    swapon /var/lib/thoxay.swap
    grep -qF '/var/lib/thoxay.swap ' /etc/fstab || printf '/var/lib/thoxay.swap none swap sw 0 0\n' >> /etc/fstab
fi

if [[ $database_mode == new ]]; then
    apt-get install -y docker.io
    systemctl enable --now docker
    if [[ ! -s /etc/thoxay/backend.env ]]; then
        db_password=$(openssl rand -hex 32)
        jwt_secret=$(openssl rand -base64 48 | tr -d '\n')
        printf 'POSTGRES_DB=tho_xay_db\nPOSTGRES_USER=thoxay\nPOSTGRES_PASSWORD=%s\n' "$db_password" > /etc/thoxay/postgres.env
        printf 'DB_URL=jdbc:postgresql://127.0.0.1:5432/tho_xay_db\nDB_USERNAME=thoxay\nDB_PASSWORD=%s\nJWT_SECRET=%s\n' \
            "$db_password" "$jwt_secret" > /etc/thoxay/backend.env
        unset db_password jwt_secret
    fi
    [[ -s /etc/thoxay/postgres.env ]] || fail 'Missing existing PostgreSQL configuration.'
    if docker container inspect thoxay-postgres >/dev/null 2>&1; then
        docker start thoxay-postgres >/dev/null
    else
        docker run -d --name thoxay-postgres --restart unless-stopped \
            --memory=384m --memory-swap=768m --env-file /etc/thoxay/postgres.env \
            -p 127.0.0.1:5432:5432 -v thoxay_postgres_data:/var/lib/postgresql/data \
            postgres:17-alpine -c shared_buffers=64MB -c max_connections=20 -c work_mem=2MB >/dev/null
    fi
    db_ready=false
    for ((attempt=0; attempt<60; attempt++)); do
        if docker exec thoxay-postgres pg_isready -U thoxay -d tho_xay_db >/dev/null 2>&1; then
            db_ready=true
            break
        fi
        sleep 2
    done
    [[ $db_ready == true ]] || fail 'PostgreSQL is not ready; existing volumes have been preserved.'
elif [[ -s "$bundle/backend.env" ]]; then
    install -m 600 "$bundle/backend.env" /etc/thoxay/backend.env
    rm -f -- "$bundle/backend.env"
fi

# These deployment-owned keys are regenerated; DB credentials and JWT remain intact.
sed -i '/^CORS_ORIGINS=/d; /^SERVER_TOMCAT_THREADS_MAX=/d; /^SERVER_TOMCAT_THREADS_MIN_SPARE=/d' /etc/thoxay/backend.env
printf '\nCORS_ORIGINS=%s\nSERVER_TOMCAT_THREADS_MAX=40\nSERVER_TOMCAT_THREADS_MIN_SPARE=4\n' "$web_origin" >> /etc/thoxay/backend.env
chmod 600 /etc/thoxay/*.env

release=$(sha256sum "$bundle/backend.jar" | cut -d ' ' -f 1)
install -m 644 "$bundle/backend.jar" "/opt/thoxay/releases/$release.jar"
if [[ -L /opt/thoxay/current.jar && $(readlink /opt/thoxay/current.jar) != "/opt/thoxay/releases/$release.jar" ]]; then
    ln -sfn -- "$(readlink /opt/thoxay/current.jar)" /opt/thoxay/previous.jar
fi
ln -sfn -- "/opt/thoxay/releases/$release.jar" /opt/thoxay/current.jar
install -m 644 "$bundle/thoxay.service" /etc/systemd/system/thoxay.service
systemctl daemon-reload
systemctl enable thoxay
systemctl restart thoxay
backend_ready=false
for ((attempt=0; attempt<90; attempt++)); do
    if curl --fail --silent --max-time 3 http://127.0.0.1:8080/health | grep -q '"UP"'; then
        backend_ready=true
        break
    fi
    sleep 2
done
[[ $backend_ready == true ]] || fail 'Backend health failed. Inspect: sudo journalctl -u thoxay -n 100. Do not switch the web API yet.'

# Preserve Certbot's existing HTTPS configuration on repeated deployments.
if [[ ! -e /etc/nginx/sites-available/thoxay ]]; then
    sed "s/__API_DOMAIN__/$api_domain/g" "$bundle/nginx.conf.template" > /etc/nginx/sites-available/thoxay
else
    grep -qF "server_name $api_domain;" /etc/nginx/sites-available/thoxay || fail 'Existing Nginx hostname differs; review it before continuing.'
fi
chmod 644 /etc/nginx/sites-available/thoxay
ln -sfn /etc/nginx/sites-available/thoxay /etc/nginx/sites-enabled/thoxay
nginx -t
systemctl enable --now nginx
systemctl reload nginx
certbot --nginx --non-interactive --agree-tos --register-unsafely-without-email --redirect --keep-until-expiring -d "$api_domain"
systemctl enable --now certbot.timer
curl --fail --silent --show-error --max-time 15 "https://$api_domain/health" | grep -q '"UP"' || fail 'Public HTTPS health check failed.'
printf '\nBackend is healthy: https://%s/health\nAdmin: https://%s/admin/login\n' "$api_domain" "$api_domain"
printf 'The existing web and APK API settings have not been switched. Verify data before switching them.\n'
