{ config, pkgs, lib, ... }:

let
  # Catppuccin GRUB base theme
  catppuccinGrub = pkgs.fetchzip {
    url  = "https://github.com/catppuccin/grub/archive/refs/heads/main.tar.gz";
    hash = "sha256-jgM22pvCQvb0bjQQXoiqGMgScR9AgCK3OfDF5Ud+/mk=";
  };

  # Custom GRUB theme: Keith + left-aligned menu + Catppuccin Mocha colors
  grubTheme = pkgs.runCommand "grub-theme-keith" { } ''
    cp -r ${catppuccinGrub}/src/catppuccin-mocha-grub-theme $out
    chmod -R u+w $out

    # Replace background and logo with Keith the rat
    cp ${./keith_bg-removebg-preview.png} $out/background.png
    cp ${./keith_bg-removebg-preview.png} $out/logo.png

    # Patch theme.txt:
    # - left-align the boot menu (not centered with cutoff)
    # - widen it so entries aren't truncated
    # - left-align the timeout label
    cat > $out/theme.txt << 'EOF'
# Catppuccin Mocha + Keith the Rat

title-text: ""
desktop-image: "background.png"
desktop-image-scale-method: "none"
desktop-color: "#1E1E2E"
terminal-font: "Unifont Regular 16"
terminal-left: "0"
terminal-top: "0"
terminal-width: "100%"
terminal-height: "100%"
terminal-border: "0"

+ boot_menu {
  left = 5%
  top = 20%
  width = 50%
  height = 65%
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
  top = 88%
  left = 5%
  width = 50%
  align = "left"
  id = "__timeout__"
  text = "Booting in %d seconds"
  color = "#A6ADC8"
  font = "Unifont Regular 14"
}
EOF
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
      animation     = "matrix";
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
