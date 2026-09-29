profile_riftdeck() {
    profile_standard
    kernel_cmdline="console=tty0 quiet loglevel=3"
    apks="$apks
        flatpak
        chromium
        mesa-dri-gallium
        mesa-va-gallium
        mesa-vulkan-intel
        mesa-vulkan-radeon
        gamescope
        steam-devices
        elogind
        polkit
        dbus
        networkmanager
        networkmanager-wifi
        networkmanager-cli
        networkmanager-tui
        wireless-tools
        wpa_supplicant
        alsa-utils
        pipewire
        pipewire-pulse
        pipewire-alsa
        wireplumber
        bluez
        bluez-openrc
        pipewire-spa-bluez
        hidapi
        font-noto
        font-noto-emoji
        ttf-dejavu
        nano
        vim
        htop
        git
        curl
        wget
        bash
        sudo
        util-linux
        e2fsprogs
        dosfstools
        ntfs-3g
        exfat-utils
        gnome-software
        gnome-software-plugin-flatpak
        cryptsetup"

    apkovl="genapkovl-riftdeck.sh"

    for _k in $kernel_flavors; do
        apks="$apks linux-$_k"
    done
    apks="$apks linux-firmware linux-firmware-none"
}
