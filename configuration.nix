{ config, pkgs, lib, ... }:

let
  # Minimal GRUB theme: Keith background + Catppuccin Mocha colours, no external deps
  grubTheme = pkgs.runCommand "grub-theme-keith" { } ''
    mkdir -p $out
    cp ${./keith_bg-removebg-preview.png} $out/background.png
    cat > $out/theme.txt << 'EOF'
title-text: ""
desktop-image: "background.png"
desktop-color: "#1E1E2E"

+ boot_menu {
  left = 5%
  top = 25%
  width = 55%
  height = 55%
  item_color = "#CDD6F4"
  selected_item_color = "#1E1E2E"
  selected_background_color = "#CBA6F7"
  item_height = 36
  item_padding = 4
  item_spacing = 4
}

+ label {
  top = 88%
  left = 5%
  width = 55%
  align = "left"
  id = "__timeout__"
  text = "Booting in %d seconds"
  color = "#A6ADC8"
}
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

  # ── Login manager — ly (TUI, minimal, Catppuccin-friendly) ────────────────
  services.displayManager.ly = {
    enable = true;
    settings = {
      animation     = "dots";
      clock         = "%c";
      vi_mode       = false;
    };
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
