# Session Passoff — NixOS + DWM ThinkPad Build

## Repo structure
NixOS flake on nixpkgs 26.05 + Home Manager release-26.05.

| File | Purpose |
|---|---|
| `flake.nix` | inputs + outputs |
| `configuration.nix` | system: hardware, services, GRUB, SDDM, dmenu overlay, system packages |
| `home.nix` | user: packages, kitty, dunst, GTK, yazi, autostart, wallpaper, cheatsheet |
| `dwm/config.def.h` | **all DWM keybinds, colors, rules — edit this** |
| `dwm/dwm.c` | patched DWM source |
| `dmenu/config.def.h` | patched dmenu colors + center/border/lineheight options |
| `build.sh` | builds system + home, then commits (pass a label as $1) |
| `homebuild.sh` | rebuilds home-manager only (no sudo) |
| `label` | current build label string (read by configuration.nix → GRUB entry name) |
| `background.jpg` | wallpaper used by feh (DWM desktop) and SDDM login screen |
| `keith_bg-removebg-preview.png` | Keith the rat (transparent PNG) — composited into GRUB background |

> **Critical DWM build rule**: never commit `dwm/config.h`. The Makefile generates it from `config.def.h` at build time. If `config.h` exists in the tree, every change to `config.def.h` is silently ignored. It was deleted in session 2 after causing months of invisible no-ops.

---

## Theme — Catppuccin Mocha throughout

| Color | Hex | Used for |
|---|---|---|
| Base | `#1e1e2e` | backgrounds, bar bg |
| Surface0 | `#313244` | inactive borders |
| Text | `#cdd6f4` | normal text |
| Mauve | `#cba6f7` | accent, selected items, borders |
| Red | `#e78284` | urgent windows (SchemeUrg) |

DWM schemes: `SchemeNorm`, `SchemeSel`, `SchemeUrg` (3-entry colors array).

> **Note**: `col_red` in `dwm/config.def.h` is currently `#89b4fa` (blue) — left in place from a color-pipeline verification test. Change it back to `#e78284` whenever you want Catppuccin red on urgent windows.

---

## DWM patches applied (all in `dwm/dwm.c`)

| Patch | Status |
|---|---|
| autostart | ✅ runs `~/.dwm/autostart.sh` |
| alwayscenter | ✅ floating windows spawn centered |
| attachbottom | ✅ new windows go to bottom of stack |
| systray | ✅ system tray in bar (manual hunk #4 fix) |
| gaps (manual) | ✅ 8px gaps in tile + monocle |
| movestack (manual) | ✅ `Mod+Shift+J/K` reorders stack |
| status2d (manual) | ✅ `drawstatusbar()` function inserted before `drawbar()`; parses `^c#RRGGBB^`, `^b#RRGGBB^`, `^d^` |

---

## DWM keybindings

| Key | Action |
|---|---|
| `Mod+Enter` | kitty terminal |
| `Mod+p` | dmenu_run |
| `Mod+s` | settings menu (dmenu: Display/Audio/Bluetooth/Network/Brightness) |
| `Mod+e` | yazi file browser in kitty |
| `Mod+v` | clipboard history via greenclip + dmenu |
| `Mod+j/k` | focus next/prev |
| `Mod+Shift+j/k` | movestack |
| `Mod+h/l` | resize master |
| `Mod+i/d` | inc/dec nmaster |
| `Mod+t/f/m` | tile / float / monocle layout |
| `Mod+b` | toggle bar |
| `Mod+0` | view all tags |
| `Mod+Shift+c` | kill client |
| `Mod+Shift+q` | quit DWM |
| `Mod+,/.` | focus prev/next monitor |
| `XF86Audio*` | wpctl volume |
| `XF86Brightness*` | brightnessctl |
| `Print` | scrot screenshot → `~/Pictures/scrot/` |

---

## Status bar (autostart.sh, updates every ~2s)

Segments (left → right): `CPU  RAM  BAT  BT  VOL  WIFI  DATE`

Colors via status2d `^c#hex^..^d^`:
- CPU `󰻠` green `#a6e3a1`
- RAM `󰍛` blue `#89b4fa`
- Battery (icon varies by %) yellow `#f9e2af`, format: `󰁾 69%-2h30m`
- Bluetooth `󰂯/󰂲` pink `#f5c2e7`
- Volume `󰕾/󰸈` mauve `#cba6f7`
- Wifi `󰤨/󰤥/󰤢/󰤯/󰤭` sky `#89dceb`
- Clock `󰥔` text `#cdd6f4`

Battery reads `BAT0` or `BAT1` (whichever exists). Uses `acpi` / sysfs.

---

## System services & hardware (`configuration.nix`)

- **Bootloader**: GRUB EFI, `useOSProber = true`, `configurationLimit = 20`
- **GRUB theme**: catppuccin-mocha assets + Keith centered at top (imagemagick composites `keith_bg-removebg-preview.png` 340×340 onto `#1E1E2E` 1920×1080 canvas). Boot menu below at 53%.
- **Login manager**: SDDM with `catppuccin-mocha-mauve` theme; `sddmTheme` derivation in `configuration.nix` copies the theme and replaces `backgrounds/wall.jpg` with `background.jpg`.
- **Display**: X11, xkb us, libinput (natural scroll, tap, middleEmulation)
- **Compositor**: picom (vsync)
- **Audio**: PipeWire (alsa + pulse compat), rtkit
- **Bluetooth**: hardware.bluetooth + blueman
- **Backlight**: acpilight + brightnessctl
- **Power**: TLP (schedutil on AC, powersave on bat, no charge thresholds)
- **Multimonitor**: `services.autorandr.enable = true`
- **dconf**: `programs.dconf.enable = true` (needed for GTK/home-manager theming)
- **dmenu**: built from `./dmenu` source via `nixpkgs.overlays`; must also be in `environment.systemPackages`
- **Firefox zoom**: `environment.sessionVariables.MOZ_USE_XINPUT2 = "1"` (touchpad pinch-to-zoom on X11)
- **Screen lock**: `programs.slock.enable = true` (setuid locker); `services.logind.lidSwitch = "lock"` (lid close → lock signal)
- **Auto-suspend**: `xss-lock` + `xautolock` in system packages; wired up in autostart.sh

---

## Home Manager (`home.nix`)

### Key packages
`nerd-fonts.jetbrains-mono`, `noto-fonts-color-emoji`, `gh`, `yazi`, `ueberzugpp`, `pasystray`, `blueman`, `pavucontrol`, `haskellPackages.greenclip`, `acpi`, `wmctrl`, `xdg-utils`

### Theming
- **Kitty**: Catppuccin Mocha, JetBrainsMono Nerd Font Mono 11pt, 8px padding
- **Dunst**: Catppuccin Mocha, urgent = red bg
- **GTK**: `catppuccin-mocha-mauve-standard+default`, Papirus-Dark icons, Catppuccin-Mocha-Dark-Cursors
- **Yazi**: Catppuccin Mocha theme via `~/.config/yazi/theme.toml`

### Managed files
- `~/.dwm/autostart.sh` — starts: feh wallpaper, greenclip daemon, nm-applet, blueman-applet, pasystray, xss-lock, xautolock, kitty cheatsheet (tag 9), status bar loop
- `~/.config/wallpaper.jpg` — sourced from `./background.jpg`
- `~/.local/share/cheatsheet` — sourced from `./cheatsheet/cheatsheet.txt`

---

## Lid close / lock / sleep

Flow: lid closes → logind sends lock event → xss-lock runs slock (password prompt) → after 5 min no keyboard/mouse input → xautolock triggers `systemctl suspend`.

- To adjust the idle-suspend timer: change `-time 5` in the `xautolock` line in `home.nix` autostart (value is in minutes).
- Side effect by design: also suspends after 5 min of idle with lid open (battery saving).

---

## Known pending

### ⚠️ Home-manager dconf build error (recurring)
- Error: `GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name is not activatable`
- Fix attempt: `programs.dconf.enable = true` in configuration.nix (system rebuild required first, then home rebuild)
- If home-manager still fails after system rebuild, the GTK/dconf activation is the blocker.

### ⚠️ First-time multimonitor setup
```sh
arandr   # arrange monitors → File > Save As "docked"
autorandr --save docked
autorandr --save mobile   # with external monitor unplugged
```

### ⚠️ gh CLI needs auth
```sh
gh auth login
```

---

## Build workflow

```sh
# Full rebuild (system + home), then git commit
./build.sh "label-no-spaces"

# Home-manager only (no sudo)
./homebuild.sh "optional commit message"

# The label file is written by build.sh and read by configuration.nix
# to name the GRUB boot entry. Keep it alphanumeric+dashes.
cat label
```
