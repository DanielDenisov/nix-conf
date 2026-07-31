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

    # Nerd Font (includes all icons used in status bar)
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-emoji

    # Systray / GUI tools
    pasystray      # audio tray icon with volume dropdown
    blueman        # bluetooth GUI
    pavucontrol    # audio mixer GUI

    # Utilities
    wmctrl
    xdg-utils
    xdg-user-dirs
    acpi           # battery time remaining
  ];

  fonts.fontconfig.enable = true;

  programs.git = {
    enable = true;
    settings.user = {
      name = "Daniel";
      email = "github@danieldenisov.com";
    };
  };

  # Kitty — Catppuccin Mocha + JetBrainsMono Nerd Font
  programs.kitty = {
    enable = true;
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };
    settings = {
      # Catppuccin Mocha
      background           = "#1e1e2e";
      foreground           = "#cdd6f4";
      selection_background = "#313244";
      selection_foreground = "#cdd6f4";
      cursor               = "#f5e0dc";
      cursor_text_color    = "#1e1e2e";
      url_color            = "#89b4fa";

      color0  = "#45475a";  color8  = "#585b70";
      color1  = "#f38ba8";  color9  = "#f38ba8";
      color2  = "#a6e3a1";  color10 = "#a6e3a1";
      color3  = "#f9e2af";  color11 = "#f9e2af";
      color4  = "#89b4fa";  color12 = "#89b4fa";
      color5  = "#cba6f7";  color13 = "#cba6f7";
      color6  = "#89dceb";  color14 = "#89dceb";
      color7  = "#bac2de";  color15 = "#a6adc8";

      window_padding_width    = 8;
      confirm_os_window_close = 0;
    };
  };

  # Dunst — Catppuccin Mocha
  services.dunst = {
    enable = true;
    settings = {
      global = {
        font         = "JetBrainsMono Nerd Font Mono 10";
        background   = "#1e1e2e";
        foreground   = "#cdd6f4";
        frame_color  = "#cba6f7";
        frame_width  = 2;
        corner_radius = 6;
        separator_color = "#313244";
        timeout      = 5;
      };
      urgency_low = {
        background = "#1e1e2e";
        foreground = "#a6adc8";
        timeout    = 3;
      };
      urgency_normal = {
        background = "#1e1e2e";
        foreground = "#cdd6f4";
        timeout    = 5;
      };
      urgency_critical = {
        background  = "#f38ba8";
        foreground  = "#1e1e2e";
        frame_color = "#f38ba8";
        timeout     = 0;
      };
    };
  };

  # Settings menu — opened by Mod+s
  home.file.".local/bin/settings-menu" = {
    executable = true;
    text = ''
      #!/bin/sh
      choice=$(printf "Display (arandr)\nAudio (pavucontrol)\nBluetooth (blueman)\nNetwork\nBrightness +\nBrightness -" \
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
  };

  # Cheatsheet — sourced from repo, deployed to ~/.local/share/cheatsheet
  home.file.".local/share/cheatsheet".source = ./cheatsheet/cheatsheet.txt;

  # Autostart — runs on DWM start via autostart patch
  home.file.".dwm/autostart.sh" = {
    executable = true;
    text = ''
      #!/bin/sh

      # Wallpaper (Catppuccin base)
      xsetroot -solid "#1e1e2e" &

      # Systray applets (provide dropdown menus in the tray)
      nm-applet &
      blueman-applet &
      pasystray &

      # Screenshot directory
      mkdir -p ~/Pictures/scrot

      # Cheatsheet on tag 9
      kitty --title "DWM Cheatsheet" less ~/.local/share/cheatsheet &

      # Status bar — updates every ~2 seconds
      while true; do
        # CPU (2-second differential sample)
        { read -r _c u1 n1 s1 i1 w1 r1 f1 t1 _rest; } < /proc/stat
        sleep 2
        { read -r _c u2 n2 s2 i2 w2 r2 f2 t2 _rest; } < /proc/stat
        dtotal=$(( (u2+n2+s2+i2+w2+r2+f2+t2) - (u1+n1+s1+i1+w1+r1+f1+t1) ))
        didle=$(( i2 - i1 ))
        [ "$dtotal" -gt 0 ] && cpu=$(( (dtotal-didle)*100/dtotal )) || cpu=0

        # RAM used (no max shown per request)
        ram=$(awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{
          u=(t-a)/1024
          if (u>=1024) printf "%.1fG",u/1024; else printf "%dM",u
        }' /proc/meminfo)

        # Battery — try BAT0 then BAT1
        bp=""
        for b in BAT0 BAT1; do
          [ -d "/sys/class/power_supply/$b" ] && bp="/sys/class/power_supply/$b" && break
        done
        if [ -n "$bp" ]; then
          cap=$(cat "$bp/capacity"  2>/dev/null || echo "?")
          bst=$(cat "$bp/status"    2>/dev/null || echo "?")
          case "$bst" in
            Charging) bicon="󰂄" ;;
            Full)     bicon="󰁹" ;;
            *)
              if   [ "$cap" -ge 90 ] 2>/dev/null; then bicon="󰁹"
              elif [ "$cap" -ge 70 ] 2>/dev/null; then bicon="󰂀"
              elif [ "$cap" -ge 50 ] 2>/dev/null; then bicon="󰁾"
              elif [ "$cap" -ge 30 ] 2>/dev/null; then bicon="󰁼"
              elif [ "$cap" -ge 15 ] 2>/dev/null; then bicon="󰁻"
              else bicon="󰁺"; fi ;;
          esac
          # Remaining time (only meaningful while discharging)
          rtime=""
          if [ "$bst" = "Discharging" ]; then
            if [ -f "$bp/energy_now" ] && [ -f "$bp/power_now" ]; then
              enow=$(cat "$bp/energy_now"); pnow=$(cat "$bp/power_now")
              [ "$pnow" -gt 0 ] && {
                mins=$(( enow*60/pnow ))
                rtime=" $(( mins/60 ))h$(( mins%60 ))m"
              }
            elif command -v acpi >/dev/null 2>&1; then
              rtime=$(acpi -b 2>/dev/null | grep -o '[0-9]*:[0-9]*:[0-9]*' | head -1 | cut -d: -f1-2 | sed 's/:/ h/')
              [ -n "$rtime" ] && rtime=" ''${rtime}m"
            fi
          fi
          bat="''${bicon} ''${cap}%''${rtime}"
        else
          bat="no bat"
        fi

        # Volume
        vol_raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0")
        vol=$(printf "%s" "$vol_raw" | awk '{printf "%d", $2*100}')
        printf "%s" "$vol_raw" | grep -q MUTED && vicon="󰸈" || vicon="󰕾"

        DATE=$(date "+%a %d %b  %H:%M")
        xsetroot -name "  󰻠 ''${cpu}%   󰍛 ''${ram}   ''${bat}   ''${vicon} ''${vol}%   󰥔 ''${DATE}  "
      done &
    '';
  };

  programs.home-manager.enable = true;
}
