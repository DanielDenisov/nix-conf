# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixdan";

  # Networking — NetworkManager handles wifi + ethernet
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # X11 + DWM
  services.xserver = {
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };
    windowManager.dwm = {
      enable = true;
      package = pkgs.dwm.overrideAttrs {
        src = ./dwm;
      };
    };
    # Touchpad
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        middleEmulation = true;
      };
    };
  };

  # Compositor
  services.picom = {
    enable = true;
    vSync = true;
  };

  # Audio (PipeWire)
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  services.blueman.enable = true;

  # Backlight / brightness control
  hardware.acpilight.enable = true;

  # Power management — TLP for ThinkPad battery life
  # No charge thresholds set: battery charges to 100% normally.
  # (Thresholds can be added later if you want to cap at 80% for longevity.)
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC  = "schedutil";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    };
  };
  # thermald intentionally disabled — ThinkPads use EC-based thermal control;
  # thermald fights with it and can cause unnecessary fan spin.

  # Multi-monitor — autorandr runs on login/hotplug via systemd
  services.autorandr.enable = true;

  # Network manager applet in systray
  programs.nm-applet.enable = true;

  # Define a user account.
  users.users.nixdan = {
    isNormalUser = true;
    description = "nixdan";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "bluetooth" ];
    packages = with pkgs; [];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    xclip
    xorg.xrandr
    arandr          # GUI for xrandr (drag monitors around)
    brightnessctl   # brightness control
    scrot           # screenshots
    feh             # wallpaper / image viewer
    libnotify
    dunst           # notification daemon
    xdotool
    pamixer         # PipeWire/PulseAudio CLI volume control
    wireplumber     # PipeWire session manager
  ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken.
  system.stateVersion = "24.11";
}
