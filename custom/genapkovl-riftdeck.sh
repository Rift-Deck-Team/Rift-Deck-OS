#!/bin/sh
HOSTNAME="riftdeck"

rc_add() {
    mkdir -p "$rootfs/etc/runlevels/$2"
    ln -sf "/etc/init.d/$1" "$rootfs/etc/runlevels/$2/$1"
}

rc_add networkmanager default
rc_add dbus default
rc_add elogind default
rc_add polkit default
rc_add bluetooth default
rc_add pipewire default
rc_add wireplumber default

echo "$HOSTNAME" > "$rootfs/etc/hostname"

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

cat > "$rootfs/usr/local/bin/riftdeck-setup" << 'EOF'
#!/bin/sh
if [ -f /root/.riftdeck-done ]; then exit 0; fi

# 1. Add YOUR Rift Store remote (not Flathub)
flatpak remote-add --if-not-exists riftstore \
    https://Rift-Deck-Team.github.io/rift-deck-os/riftstore.flatpakrepo

# 2. Add Flathub as fallback for dependencies
flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo

# 3. Install Steam
flatpak install -y --noninteractive flathub com.valvesoftware.Steam

# 4. Install Edge for Xbox Cloud
flatpak install -y --noninteractive flathub com.microsoft.Edge
flatpak override --user --filesystem=/run/udev:ro com.microsoft.Edge

# 5. Install Bazaar storefront
flatpak install -y --noninteractive flathub io.github.kolunmi.Bazaar

# 6. Install RetroDECK from YOUR store
flatpak install -y --noninteractive riftstore net.retrodeck.retrodeck

touch /root/.riftdeck-done
EOF
chmod +x "$rootfs/usr/local/bin/riftdeck-setup"

cat > "$rootfs/usr/local/bin/riftdeck-console" << 'EOF'
#!/bin/sh
export XDG_SESSION_TYPE=x11
export XDG_RUNTIME_DIR=/run/user/0
/usr/local/bin/riftdeck-setup
exec gamescope -f -- flatpak run com.valvesoftware.Steam -bigpicture
EOF
chmod +x "$rootfs/usr/local/bin/riftdeck-console"

cat > "$rootfs/etc/profile.d/riftdeck.sh" << 'EOF'
if [ "$(tty)" = "/dev/tty1" ] && [ -z "$DISPLAY" ]; then
    exec /usr/local/bin/riftdeck-console
fi
EOF
chmod +x "$rootfs/etc/profile.d/riftdeck.sh"
