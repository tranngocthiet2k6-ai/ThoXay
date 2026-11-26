#!/usr/bin/env bash
set -euo pipefail

api_domain=${1:?Supply the public API hostname}
[[ $EUID -eq 0 ]] || { echo 'Run with sudo.' >&2; exit 1; }
[[ $api_domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9.-]*[a-zA-Z0-9])?$ && $api_domain == *.* ]] || { echo 'Invalid API hostname.' >&2; exit 1; }
bundle=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
install -d -o www-data -g www-data -m 750 /var/cache/nginx/thoxay-map-tiles
site=/etc/nginx/sites-available/thoxay
backup=''
enabled_before=false
[[ ! -e /etc/nginx/sites-enabled/thoxay && ! -L /etc/nginx/sites-enabled/thoxay ]] || enabled_before=true
if [[ -f $site ]]; then
    grep -qF "server_name $api_domain;" "$site" || { echo 'Existing API hostname differs.' >&2; exit 1; }
    backup=$(mktemp /etc/nginx/thoxay.previous.XXXXXX)
    cp -p -- "$site" "$backup"
fi

restore_previous() {
    if [[ -n $backup ]]; then
        cp -p -- "$backup" "$site"
    else
        rm -f -- "$site"
    fi
    if [[ $enabled_before == false ]]; then
        rm -f -- /etc/nginx/sites-enabled/thoxay
    fi
}
trap restore_previous ERR
python3 - "$bundle/nginx.conf.template" "$site" "$api_domain" <<'PY'
from pathlib import Path
import re
import sys

template_path, site_path, domain = sys.argv[1:]
site = Path(site_path)
previous = site.read_text() if site.exists() else ''
rendered = Path(template_path).read_text().replace('__API_DOMAIN__', domain)
if re.search(r'^\s*listen\s+443\s', previous, re.M):
    tls = re.findall(r'^\s*(?:ssl_certificate(?:_key)?\s+[^;]+;|ssl_dhparam\s+[^;]+;|include\s+/etc/letsencrypt/[^;]+;)', previous, re.M)
    if not any(re.match(r'\s*ssl_certificate\s', line) for line in tls) or not any('ssl_certificate_key' in line for line in tls):
        raise SystemExit('Existing HTTPS configuration is incomplete; refusing to replace it.')
    # Ubuntu 24.04 ships Nginx 1.24: HTTP/2 is configured on listen.
    rendered = rendered.replace('    listen 80;', '    listen 443 ssl http2;', 1)
    anchor = f'    server_name {domain};'
    rendered = rendered.replace(anchor, anchor + '\n' + '\n'.join('    ' + line.strip() for line in tls), 1)
    rendered += f'''
server {{
    listen 80;
    server_name {domain};
    location ^~ /.well-known/acme-challenge/ {{
        root /var/www/html;
    }}
    location / {{
        return 301 https://$host$request_uri;
    }}
}}
'''
site.write_text(rendered)
PY
chmod 644 "$site"
ln -sfn "$site" /etc/nginx/sites-enabled/thoxay
nginx -t
systemctl enable --now nginx
systemctl reload nginx
trap - ERR
printf 'Nginx configured; previous config: %s\n' "${backup:-none (first installation)}"
