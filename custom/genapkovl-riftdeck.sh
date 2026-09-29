#!/bin/sh
HOSTNAME="riftdeck"

rc_add() {
    mkdir -p "$rootfs/etc/runlevels/$2"
    ln -sf "/etc/init.d/$1" "$rootfs/etc/runlevels/$2/$1"
}

# Enable services (WiFi, Bluetooth, Audio)
rc_add networkmanager default
rc_add dbus default
rc_add elogind default
rc_add polkit default
rc_add bluetooth default
rc_add pipewire default
rc_add wireplumber default

echo "$HOSTNAME" > "$rootfs/etc/hostname"

# NetworkManager config for WiFi
mkdir -p "$rootfs/etc/NetworkManager"
cat > "$rootfs/etc/NetworkManager/NetworkManager.conf" << 'EOF'
[main]
dhcp=internal
plugins=ifupdown,keyfile

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=yes
wifi.backend=wpa_supplicant
EOF

# Auto-login on tty1
mkdir -p "$rootfs/etc/inittab.d"
cat > "$rootfs/etc/inittab.d/autologin.conf" << 'EOF'
tty1::respawn:/sbin/getty -n -l /usr/local/bin/riftdeck-login 38400 tty1
EOF

mkdir -p "$rootfs/usr/local/bin"

cat > "$rootfs/usr/local/bin/riftdeck-login" << 'EOF'
#!/bin/sh
exec /bin/login -f root
EOF
chmod +x "$rootfs/usr/local/bin/riftdeck-login"

# First boot setup
cat > "$rootfs/usr/local/bin/riftdeck-setup" << 'EOF'
#!/bin/sh
if [ -f /root/.riftdeck-done ]; then exit 0; fi

# Add Rift Store remote (your curated store)
flatpak remote-add --if-not-exists riftstore \
    https://Rift-Deck-Team.github.io/rift-deck-os/riftstore.flatpakrepo

# Add Flathub for dependencies
flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

# Install Steam (requires glibc, must use Flatpak)
flatpak install -y --noninteractive flathub com.valvesoftware.Steam

# Install Edge for Xbox Cloud Gaming
flatpak install -y --noninteractive flathub com.microsoft.Edge
flatpak override --user --filesystem=/run/udev:ro com.microsoft.Edge

# Install Bazaar storefront
flatpak install -y --noninteractive flathub io.github.kolunmi.Bazaar

# Install RetroDECK from Rift Store
flatpak install -y --noninteractive riftstore net.retrodeck.retrodeck

touch /root/.riftdeck-done
EOF
chmod +x "$rootfs/usr/local/bin/riftdeck-setup"

# Console launcher
cat > "$rootfs/usr/local/bin/riftdeck-console" << 'EOF'
#!/bin/sh
export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR=/run/user/0
/usr/local/bin/riftdeck-setup
exec gamescope -f -- flatpak run com.valvesoftware.Steam -bigpicture
EOF
chmod +x "$rootfs/usr/local/bin/riftdeck-console"

# Auto-start console on login
cat > "$rootfs/etc/profile.d/riftdeck.sh" << 'EOF'
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ]; then
    exec /usr/local/bin/riftdeck-console
fi
EOF
chmod +x "$rootfs/etc/profile.d/riftdeck.sh"

# Developer mode script (code: RIFT2026)
cat > "$rootfs/usr/local/bin/riftdeck-dev" << 'EOF'
#!/bin/sh
echo "Enter Developer Code:"
read code
if [ "$code" = "RIFT2026" ]; then
    echo "Developer Mode Unlocked"
    echo "1. User Management"
    echo "2. System Stats"
    echo "3. Desktop Mode"
    echo "4. Exit"
    read choice
    case $choice in
        1) echo "Users:"; ls /home/ ;;
        2) echo "Play time data coming soon" ;;
        3) exec startx ;;
        4) exit 0 ;;
    esac
fi
EOF
chmod +x "$rootfs/usr/local/bin/riftdeck-dev"
