#!/bin/bash
# Nginx configuration for sabnzbd
# Author: liara
# Copyright (C) 2017 Swizzin
# Licensed under GNU General Public License v3.0 GPL-3 (in short)
#
#   You may copy, distribute and modify the software as long as you track
#   changes/dates in source files. Any modifications to our software
#   including (via compiler) GPL-licensed code must also be made available
#   under the GPL along with build & install instructions.
user=$(cut -d: -f1 < /root/.master.info)
active=$(systemctl is-active sabnzbd)

if [[ $active == "active" ]]; then
    systemctl stop sabnzbd
fi

if [[ ! -f /etc/nginx/apps/sabnzbd.conf ]]; then
    cat > /etc/nginx/apps/sabnzbd.conf << SAB
location /sabnzbd {
  include /etc/nginx/snippets/proxy.conf;
  proxy_pass        http://127.0.0.1:65080/sabnzbd;
  auth_basic "What's the password?";
  auth_basic_user_file /etc/htpasswd.d/htpasswd.${user};
}
SAB
fi

sabini="/home/${user}/.config/sabnzbd/sabnzbd.ini"
sed -i "s|^host = .*|host = 127.0.0.1|g" "$sabini"
# SABnzbd defaults url_base to "" and may not write the key at all, so set it or add it under [misc]
if grep -qE '^\s*url_base\s*=' "$sabini"; then
    sed -i -E 's|^\s*url_base\s*=.*|url_base = /sabnzbd|' "$sabini"
else
    sed -i 's|^\[misc\]$|[misc]\nurl_base = /sabnzbd|' "$sabini"
fi
# Behind nginx, SABnzbd sees the real client IP from X-Forwarded-For and denies external clients by default.
# Level 4 allows the full web UI. The SABnzbd login and nginx basic auth stay in place.
if grep -qE '^\s*inet_exposure\s*=' "$sabini"; then
    sed -i -E 's|^\s*inet_exposure\s*=.*|inet_exposure = 4|' "$sabini"
else
    sed -i 's|^\[misc\]$|[misc]\ninet_exposure = 4|' "$sabini"
fi

if [[ $active == "active" ]]; then
    systemctl start sabnzbd
fi
