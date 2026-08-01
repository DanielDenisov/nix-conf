{ config, pkgs, lib, ... }:

let
  # Catppuccin GRUB theme — fetched from upstream
  catppuccinGrub = pkgs.fetchFromGitHub {
    owner = "catppuccin";
    repo  = "grub";
    rev   = "803bc3705be57a31a2c3d6c2f91fe1cb59c1ec0b";
    hash  = "sha256-/bSolCta8GCZ4lP0u5NVqYQ9Y3ZooORZAFRQ0NBnfSY=";
  };

  # Build label — written by buildsys.sh before each rebuild
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
    theme               = "${catppuccinGrub}/src/catppuccin-mocha-grub-theme";
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
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping          = true;
        middleEmulation  = true;
      };
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
  hardware.pulseaudio.enable = false;
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
    xclip
    xorg.xrandr
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
