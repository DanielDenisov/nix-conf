{ config, pkgs, lib, ... }:

let
  # Catppuccin GRUB base theme (catppuccin logo + dark bg — restored)
  catppuccinGrub = pkgs.fetchzip {
    url  = "https://github.com/catppuccin/grub/archive/refs/heads/main.tar.gz";
    hash = "sha256-jgM22pvCQvb0bjQQXoiqGMgScR9AgCK3OfDF5Ud+/mk=";
  };

  # GRUB theme: original catppuccin aesthetic (small logo centred in dark bg)
  # with a wider menu so long NixOS labels don't get cut off
  grubTheme = pkgs.runCommand "grub-theme-catppuccin" { } ''
    cp -r ${catppuccinGrub}/src/catppuccin-mocha-grub-theme $out
    chmod -R u+w $out
    cat > $out/theme.txt << 'EOF'
title-text: ""
desktop-image: "background.png"
desktop-color: "#1E1E2E"
terminal-font: "Unifont Regular 16"
terminal-left: "0"
terminal-top: "0"
terminal-width: "100%"
terminal-height: "100%"
terminal-border: "0"

+ boot_menu {
  left = 10%
  top = 50%
  width = 80%
  height = 45%
  item_font = "Unifont Regular 16"
  item_color = "#CDD6F4"
  selected_item_color = "#CDD6F4"
  icon_width = 32
  icon_height = 32
  item_icon_space = 20
  item_height = 36
  item_padding = 8
  item_spacing = 6
  selected_item_pixmap_style = "select_*.png"
}

+ label {
  top = 97%
  left = 10%
  width = 80%
  align = "left"
  id = "__timeout__"
  text = "Booting in %d seconds"
  color = "#A6ADC8"
  font = "Unifont Regular 14"
}
EOF
  '';

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

  # ── Bootloader — GRUB ─────────────────────────────────────────────────────
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub = {
    enable              = true;
    device              = "nodev";
    efiSupport          = true;
    useOSProber         = true;        # detect Windows/other OSes
    configurationLimit  = 20;          # keep 20 generations; older ones in submenu
    theme               = grubTheme;
  };

  # Build label shown in GRUB entry (set by buildsys.sh)
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
    extraGroups   = [ "networkmanager" "wheel" "video" "audio" "bluetooth" ];
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
  ];

  system.stateVersion = "24.11";
}
