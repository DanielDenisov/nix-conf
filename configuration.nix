{ config, pkgs, lib, ... }:

let
  # SDDM theme: catppuccin-mocha-mauve with user's wallpaper
  sddmTheme = pkgs.runCommand "catppuccin-sddm-custom" {} ''
    mkdir -p $out/share/sddm/themes/catppuccin-mocha-mauve
    cp -r ${pkgs.catppuccin-sddm}/share/sddm/themes/catppuccin-mocha-mauve/. \
           $out/share/sddm/themes/catppuccin-mocha-mauve/
    chmod -R u+w $out/share/sddm/themes/catppuccin-mocha-mauve
    cp ${./background.jpg} $out/share/sddm/themes/catppuccin-mocha-mauve/backgrounds/wall.jpg
    cat > $out/share/sddm/themes/catppuccin-mocha-mauve/theme.conf << 'EOF'
[General]
Font="JetBrainsMono Nerd Font"
FontSize=10
ClockEnabled="true"
CustomBackground="true"
LoginBackground="false"
Background="backgrounds/wall.jpg"
UserIcon="false"
EOF
  '';

  # Settings menu — system package so it's always in PATH regardless of home-manager
  settingsMenu = pkgs.writeScriptBin "settings-menu" ''
    #!/bin/sh
    choice=$(printf 'Display (arandr)\nAudio (pavucontrol)\nBluetooth (blueman)\nNetwork\nBrightness +\nBrightness -' \
             | dmenu -fn "JetBrainsMono Nerd Font Mono:size=10" \
                     -nb "#1e1e2e" -nf "#cdd6f4" -sb "#cba6f7" -sf "#1e1e2e" \
                     -p "Settings:")
    case "$choice" in
      "Display (arandr)")    arandr ;;
      "Audio (pavucontrol)") pavucontrol ;;
      "Bluetooth (blueman)") blueman-manager ;;
      "Network")             nm-connection-editor ;;
      "Brightness +")        brightnessctl set 10%+ ;;
      "Brightness -")        brightnessctl set 10%- ;;
    esac
  '';

  # Build label — written by build.sh before each rebuild
  buildLabel = if builtins.pathExists ./label
               then lib.strings.trim (builtins.readFile ./label)
               else "unnamed";
in
{
  imports = [ ./hardware-configuration.nix ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # ── Bootloader — systemd-boot ─────────────────────────────────────────────
  # No os-prober, no `device = "nodev"`, no MBR/BIOS guesswork: systemd-boot
  # only ever needs an ESP mounted at /boot. That is the whole install contract.
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot = {
    enable = true;

    # Anti-clutter: only the last few generations get a menu entry. systemd-boot
    # has no GRUB-style "advanced options" submenu, so this number IS the menu.
    configurationLimit = 5;

    consoleMode = "max";      # use the largest text mode the firmware offers
    editor      = false;      # no kernel-cmdline editing at the menu (init=/bin/sh)

    # Sort keys control menu order. NixOS entries first, Windows pinned below.
    sortKey = "a_nixos";

    # Windows needs NO config here: it lives on this same ESP
    # (/boot/EFI/Microsoft/Boot/bootmgfw.efi), so systemd-boot auto-discovers it
    # and shows it as "Windows Boot Manager". Verified via `bootctl list`
    # (type: Automatic, id: auto-windows). This is the thing os-prober was for.
  };

  # Short enough to be out of the way, long enough to actually pick Windows.
  boot.loader.timeout = 5;

  # Keeps old generations from piling up on the (small) ESP in the first place.
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };

  # Build label shown in the boot entry title (set by buildsys.sh)
  system.nixos.label = buildLabel;

  # ── Networking ────────────────────────────────────────────────────────────
  networking.hostName = "nixdan";
  networking.networkmanager.enable = true;

  # ── Locale / Time ─────────────────────────────────────────────────────────
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── X11 + DWM ─────────────────────────────────────────────────────────────
  services.xserver = {
    enable = true;
    xkb.layout = "us";
    windowManager.dwm = {
      enable  = true;
      package = pkgs.dwm.overrideAttrs { src = ./dwm; };
    };
  };

  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping          = true;
      middleEmulation  = true;
    };
  };

  # ── Login manager — SDDM with Catppuccin Mocha theme + wallpaper ─────────
  services.displayManager.sddm = {
    enable = true;
    theme  = "catppuccin-mocha-mauve";
  };

  # ── Compositor ────────────────────────────────────────────────────────────
  services.picom = {
    enable = true;
    vSync  = true;
  };

  # ── Audio (PipeWire) ──────────────────────────────────────────────────────
  services.pulseaudio.enable = false;
  security.rtkit.enable      = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  # ── Bluetooth ─────────────────────────────────────────────────────────────
  hardware.bluetooth = { enable = true; powerOnBoot = true; };
  services.blueman.enable = true;

  # ── Backlight ─────────────────────────────────────────────────────────────
  hardware.acpilight.enable = true;

  # ── Screen lock + lid behaviour ───────────────────────────────────────────
  # slock: minimal password locker (needs setuid to read /etc/shadow)
  programs.slock.enable = true;
  # Lock screen when lid closes; xss-lock in autostart.sh picks up the signal
  services.logind.lidSwitch = "lock";

  # ── Power management (TLP) ────────────────────────────────────────────────
  # No charge thresholds — battery charges to 100% normally.
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC  = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
  # thermald intentionally omitted — ThinkPad EC handles thermals natively.

  # ── Multimonitor ──────────────────────────────────────────────────────────
  services.autorandr.enable = true;

  # ── Firefox touchpad pinch-to-zoom (XInput2 multitouch on X11) ───────────
  environment.sessionVariables.MOZ_USE_XINPUT2 = "1";

  # ── dconf (required for GTK theming via Home Manager) ────────────────────
  programs.dconf.enable = true;

  # ── Network manager applet ────────────────────────────────────────────────
  programs.nm-applet.enable = true;

  # ── dmenu (from source with center + border + lineheight patches) ─────────
  nixpkgs.overlays = [
    (final: prev: {
      dmenu = prev.dmenu.overrideAttrs {
        src = ./dmenu;
      };
    })
  ];

  # ── User ──────────────────────────────────────────────────────────────────
  users.users.nixdan = {
    isNormalUser  = true;
    description   = "nixdan";
    extraGroups   = [ "networkmanager" "wheel" "video" "audio" "bluetooth" "adbusers"];
  };

  nixpkgs.config.allowUnfree = true;


  # ── System packages ───────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    dmenu           # patched via overlay — must be listed here to actually install
    settingsMenu    # Mod+s settings picker (system package so it's always in PATH)
    sddmTheme       # catppuccin SDDM theme with custom wallpaper
    xclip
    xrandr
    arandr
    brightnessctl
    scrot
    feh
    libnotify
    dunst
    xdotool
    pamixer
    wireplumber
    iw              # wifi signal strength (for status bar)
    xss-lock        # bridge between logind lock events and the screen locker
    xautolock       # suspend after 5 min of X idle (covers lid-closed idle)
  ];

  system.stateVersion = "24.11";
}
