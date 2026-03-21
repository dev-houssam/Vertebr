sudo tee /etc/systemd/system/vertebr.service << 'EOF'
[Unit]
Description=Vertebr System Configuration Daemon
After=network.target dbus.service bluetooth.target
Wants=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/usr/bin/vertebr-daemon
ExecStartPost=/bin/chmod 777 /tmp/vertebr.sock
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=vertebr

Environment=VERTEBR_CONFIG=/etc/vertebr/routes.toml
Environment=VERTEBR_MODULES=/usr/lib/vertebr/modules
Environment=VERTEBR_SOCKET=/tmp/vertebr.sock

Environment=DISPLAY=:0
Environment=XAUTHORITY=/run/user/1000/gdm/Xauthority
Environment=DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus
Environment=PULSE_SERVER=unix:/run/user/1000/pulse/native
Environment=XDG_RUNTIME_DIR=/run/user/1000
Environment=HOME=/home/houssam-core

AmbientCapabilities=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP
CapabilityBoundingSet=CAP_NET_ADMIN CAP_SYS_ADMIN CAP_SYS_BOOT CAP_DAC_OVERRIDE CAP_SETFCAP

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl restart vertebr
sudo chmod 777 /tmp/vertebr.sock
