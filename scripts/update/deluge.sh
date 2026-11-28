#!/bin/bash

if [[ -f /install/.deluge.lock ]]; then
    if grep -q ExecStop /etc/systemd/system/deluged@.service > /dev/null 2>&1; then
        sed -i '/ExecStop/d' /etc/systemd/system/deluged@.service
        reloadsys=true
    fi
    if grep -q ExecStop /etc/systemd/system/deluge-web@.service > /dev/null 2>&1; then
        sed -i '/ExecStop/d' /etc/systemd/system/deluge-web@.service
        reloadsys=true
    fi
    if [[ $reloadsys == "true" ]]; then
        echo_progress_start "Updating Deluge systemd service files"
        systemctl daemon-reload
        echo_progress_done
    fi

    # Source builds on newer releases (e.g. Debian 12) install to /usr/local/bin,
    # while older unit files always pointed to /usr/bin
    #shellcheck source=sources/functions/deluge
    . /etc/swizzin/sources/functions/deluge
    deluge_fix_execstart
    if [[ $deluge_execstart_changed == "true" ]]; then
        echo_progress_start "Pointing Deluge services to the installed executables"
        for u in $(_get_user_list); do
            for service in deluged deluge-web; do
                if systemctl -q is-enabled "${service}@${u}" 2> /dev/null; then
                    systemctl restart "${service}@${u}" >> "$log" 2>&1
                fi
            done
        done
        echo_progress_done
    fi
fi
