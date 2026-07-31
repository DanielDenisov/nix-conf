{ config, pkgs, ... }:

{
  home.username = "nixdan";
  home.homeDirectory = "/home/nixdan";

  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    git
    fastfetch
    kitty
    firefox
    claude-code

    # Fonts
    jetbrains-mono
    noto-fonts
    noto-fonts-emoji

    # Bluetooth GUI
    blueman

    # Audio GUI
    pavucontrol

    # Utilities
    wmctrl
    xdg-utils
    xdg-user-dirs
  ];

  # JetBrains Mono as default monospace
  fonts.fontconfig.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Daniel";
      email = "github@danieldenisov.com";
    };
  };

  # Dunst — notification daemon (ThinkPad colors)
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "JetBrains Mono 10";
        background = "#1a1a1a";
        foreground = "#c0c0c0";
        frame_color = "#cc0000";
        frame_width = 2;
        corner_radius = 4;
        separator_color = "#2d2d2d";
        timeout = 5;
      };
      urgency_critical = {
        background = "#cc0000";
        foreground = "#ffffff";
        timeout = 0;
      };
    };
  };

  # Cheatsheet — displayed in kitty on tag 9
  home.file.".dwm/cheatsheet" = {
    text = ''
      ╔══════════════════════════════════════════════════════════════╗
      ║              DWM CHEATSHEET  —  ThinkPad Build              ║
      ╚══════════════════════════════════════════════════════════════╝

      MODKEY = Super (Win key)

      ── WINDOWS ─────────────────────────────────────────────────────
        Mod + Shift + Enter   Open terminal (kitty)
        Mod + p               dmenu (app launcher)
        Mod + Shift + C       Kill focused window
        Mod + j / k           Focus next / previous window
        Mod + Shift + j / k   Move window down / up in stack
        Mod + Return          Zoom (swap with master)
        Mod + Shift + Space   Toggle floating
        Mod + (drag)          Move floating window
        Mod + Right-click     Resize floating window

      ── LAYOUTS ─────────────────────────────────────────────────────
        Mod + t               []=  Tile (default)
        Mod + f               ><>  Float
        Mod + m               [M]  Monocle (fullscreen stack)
        Mod + Space           Toggle last two layouts
        Mod + h / l           Shrink / grow master area
        Mod + i / d           Inc / dec number of masters

      ── TAGS (workspaces) ───────────────────────────────────────────
        Mod + 1-9             Switch to tag
        Mod + Shift + 1-9     Move window to tag
        Mod + Ctrl + 1-9      Toggle tag view
        Mod + 0               Show all tags
        Mod + Tab             Toggle previous tag
        Mod + , / .           Focus previous / next monitor
        Mod + Shift + , / .   Move window to other monitor

      ── BAR ─────────────────────────────────────────────────────────
        Mod + b               Toggle bar on/off

      ── LAPTOP FN KEYS ──────────────────────────────────────────────
        XF86AudioRaiseVolume  Volume +5%
        XF86AudioLowerVolume  Volume -5%
        XF86AudioMute         Toggle mute
        XF86BrightnessUp      Brightness +10%
        XF86BrightnessDown    Brightness -10%
        Print                 Screenshot (saved to ~/Pictures/scrot/)

      ── SESSION ─────────────────────────────────────────────────────
        Mod + Shift + Q       Quit DWM

      ── PATCHES APPLIED ─────────────────────────────────────────────
        systray       System tray in the bar (nm-applet, blueman live here)
        autostart     ~/.dwm/autostart.sh runs on DWM launch
        alwayscenter  Floating windows always spawn centered
        attachbottom  New windows attach to bottom of stack
        gaps          8px gaps between windows
        movestack     Mod+Shift+J/K to reorder windows in stack

      ── MULTIMONITOR (autorandr) ────────────────────────────────────
        First time setup:
          arandr                       drag monitors into position
          autorandr --save docked      save HDMI-connected layout
          autorandr --save mobile      save laptop-only layout

        After that, plugging/unplugging HDMI auto-switches profiles.
        Manual switch:  autorandr docked   /   autorandr mobile

      ── AUDIO & BLUETOOTH ───────────────────────────────────────────
        pavucontrol   Audio mixer GUI
        blueman       Bluetooth manager GUI   (systray icon)
        nm-applet     Network manager         (systray icon)

      ── COLORS (ThinkPad palette) ───────────────────────────────────
        Background  #1a1a1a   deep black
        Border      #2d2d2d   inactive window border
        Text        #c0c0c0   normal text
        Accent      #cc0000   ThinkPad red  (selected / active border)
        Text sel    #ffffff   text on selected

      ──────────────────────────────────────────────────────────────────
        Press q to close this cheatsheet
    '';
  };

  # Autostart script — runs when DWM starts (via autostart patch)
  home.file.".dwm/autostart.sh" = {
    executable = true;
    text = ''
      #!/bin/sh

      # Set wallpaper (solid ThinkPad black)
      xsetroot -solid "#1a1a1a" &

      # Network manager applet
      nm-applet &

      # Bluetooth applet
      blueman-applet &

      # Open cheatsheet in kitty on tag 9
      kitty --title "DWM Cheatsheet" --override font_size=10 \
        sh -c 'less -r ~/.dwm/cheatsheet' &

      # Status bar updater (battery, date)
      while true; do
        BAT=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "?")
        BAT_STATUS=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null | head -c1 || echo "?")
        DATE=$(date "+%a %d %b  %H:%M")
        xsetroot -name "  BAT: ''${BAT}% [''${BAT_STATUS}]   ''${DATE}  "
        sleep 30
      done &
    '';
  };

  programs.home-manager.enable = true;
}
