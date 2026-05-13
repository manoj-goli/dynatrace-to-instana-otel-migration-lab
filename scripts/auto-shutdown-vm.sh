#!/usr/bin/env bash
set -euo pipefail

# Installs a systemd timer that shuts down the VM daily.
# Override SHUTDOWN_TIME_UTC when running, for example:
# SHUTDOWN_TIME_UTC=23:30 ./scripts/auto-shutdown-vm.sh

SHUTDOWN_TIME_UTC="${SHUTDOWN_TIME_UTC:-23:00}"

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

$SUDO tee /etc/systemd/system/otel-mvp-auto-shutdown.service >/dev/null <<SERVICE
[Unit]
Description=Shut down the OpenTelemetry MVP VM

[Service]
Type=oneshot
ExecStart=/sbin/shutdown -h now
SERVICE

$SUDO tee /etc/systemd/system/otel-mvp-auto-shutdown.timer >/dev/null <<TIMER
[Unit]
Description=Daily auto-shutdown timer for the OpenTelemetry MVP VM

[Timer]
OnCalendar=*-*-* ${SHUTDOWN_TIME_UTC}:00 UTC
Persistent=true

[Install]
WantedBy=timers.target
TIMER

$SUDO systemctl daemon-reload
$SUDO systemctl enable --now otel-mvp-auto-shutdown.timer
$SUDO systemctl list-timers otel-mvp-auto-shutdown.timer --no-pager
