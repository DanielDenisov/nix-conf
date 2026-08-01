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
    noto-fonts-color-emoji

    # Systray / GUI tools
    pasystray      # audio tray icon with volume dropdown
    blueman        # bluetooth GUI
    pavucontrol    # audio mixer GUI

    # File explorer
    yazi
    ueberzugpp     # image preview in yazi

    # GTK icon theme for styled systray icons
    papirus-icon-theme

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

        # RAM used
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
          cap=$(cat "$bp/capacity" 2>/dev/null || echo "?")
          bst=$(cat "$bp/status"   2>/dev/null || echo "?")
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
          rtime=""
          if [ "$bst" = "Discharging" ]; then
            if [ -f "$bp/energy_now" ] && [ -f "$bp/power_now" ]; then
              enow=$(cat "$bp/energy_now"); pnow=$(cat "$bp/power_now")
              [ "$pnow" -gt 0 ] && {
                mins=$(( enow*60/pnow ))
                rtime="-$(( mins/60 ))h$(( mins%60 ))m"
              }
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

        # Bluetooth
        if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
          bticon="󰂯"
        else
          bticon="󰂲"
        fi

        # Wifi signal
        wdev=$(iw dev 2>/dev/null | awk '/Interface/{print $2; exit}')
        if [ -n "$wdev" ]; then
          sig=$(iw dev "$wdev" link 2>/dev/null | awk '/signal:/{print $2}')
          if [ -n "$sig" ]; then
            if   [ "$sig" -ge -50 ] 2>/dev/null; then wicon="󰤨"
            elif [ "$sig" -ge -65 ] 2>/dev/null; then wicon="󰤥"
            elif [ "$sig" -ge -75 ] 2>/dev/null; then wicon="󰤢"
            else wicon="󰤯"; fi
          else
            wicon="󰤭"
          fi
          S_WIFI="^c#89dceb^ ''${wicon} ^d^"
        else
          S_WIFI=""
        fi

        DATE=$(date "+%a %d %b  %H:%M")
        S_CPU="^c#a6e3a1^󰻠 ''${cpu}%^d^"
        S_RAM="^c#89b4fa^󰍛 ''${ram}^d^"
        S_BAT="^c#f9e2af^''${bat}^d^"
        S_BT="^c#f5c2e7^''${bticon}^d^"
        S_VOL="^c#cba6f7^''${vicon} ''${vol}%^d^"
        S_DATE="^c#cdd6f4^󰥔 ''${DATE}^d^"
        bar="  ''${S_CPU}  ''${S_RAM}  ''${S_BAT}  ''${S_BT}  ''${S_VOL}  ''${S_WIFI}  ''${S_DATE}  "
        xsetroot -name "$bar"
      done &
    '';
  };

  # GTK — Catppuccin Mocha theme + Papirus-Dark icons (affects systray icons)
  gtk = {
    enable = true;
    theme = {
      name    = "catppuccin-mocha-mauve-standard+default";
      package = pkgs.catppuccin-gtk.override {
        accents    = [ "mauve" ];
        variant    = "mocha";
        tweaks     = [ "normal" ];
      };
    };
    iconTheme = {
      name    = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name    = "Catppuccin-Mocha-Dark-Cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
    };
    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
  };

  # Yazi — TUI file manager with Catppuccin Mocha theme
  programs.yazi = {
    enable  = true;
    settings = {
      manager = {
        show_hidden   = false;
        show_symlink  = true;
        sort_by       = "natural";
        sort_dir_first = true;
      };
    };
    keymap = {
      manager.prepend_keymap = [
        { on = "q"; run = "quit"; desc = "Quit"; }
      ];
    };
  };

  # Yazi Catppuccin Mocha colorscheme
  home.file.".config/yazi/theme.toml".text = ''
    [manager]
    cwd = { fg = "#89b4fa" }

    hovered         = { fg = "#1e1e2e", bg = "#cba6f7" }
    preview_hovered = { underline = true }

    find_keyword  = { fg = "#f9e2af", italic = true }
    find_position = { fg = "#f5c2e7", bg = "reset", italic = true }

    marker_copied  = { fg = "#a6e3a1", bg = "#a6e3a1" }
    marker_cut     = { fg = "#f38ba8", bg = "#f38ba8" }
    marker_marked  = { fg = "#cba6f7", bg = "#cba6f7" }
    marker_selected = { fg = "#89b4fa", bg = "#89b4fa" }

    [status]
    overall  = { fg = "#cdd6f4", bg = "#1e1e2e" }
    progress = { fg = "#1e1e2e", bg = "#89b4fa" }
    sep_left  = { fg = "#313244", bg = "#1e1e2e" }
    sep_right = { fg = "#313244", bg = "#1e1e2e" }

    [input]
    border   = { fg = "#cba6f7" }
    title    = { fg = "#cba6f7" }
    value    = { fg = "#cdd6f4" }
    selected = { reversed = true }

    [select]
    border   = { fg = "#cba6f7" }
    active   = { fg = "#f5c2e7" }
    inactive = { fg = "#6c7086" }

    [tasks]
    border  = { fg = "#cba6f7" }
    title   = {}
    hovered = { underline = true }

    [which]
    mask            = { bg = "#1e1e2e" }
    cand            = { fg = "#89dceb" }
    rest            = { fg = "#6c7086" }
    desc            = { fg = "#f5c2e7" }
    separator       = "  "
    separator_style = { fg = "#585b70" }

    [notify]
    title_info  = { fg = "#a6e3a1" }
    title_warn  = { fg = "#f9e2af" }
    title_error = { fg = "#f38ba8" }

    [filetype]
    rules = [
      { mime = "image/*",     fg = "#89b4fa" },
      { mime = "video/*",     fg = "#f5c2e7" },
      { mime = "audio/*",     fg = "#cba6f7" },
      { mime = "application/zip",    fg = "#f38ba8" },
      { mime = "application/x-tar", fg = "#f38ba8" },
      { mime = "text/*",      fg = "#a6e3a1" },
      { name = "*.nix",       fg = "#89b4fa" },
      { name = "*.sh",        fg = "#a6e3a1" },
      { name = "*/",          fg = "#cba6f7" },
      { name = "*",           fg = "#cdd6f4" },
    ]
  '';

  # Keybind: Mod+e opens yazi in kitty
  # (add this line to dwm config.def.h if desired — see cheatsheet)

  programs.home-manager.enable = true;
}
