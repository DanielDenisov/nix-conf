# Session Passoff — NixOS + DWM ThinkPad Build

## What this repo is
NixOS flake config for a ThinkPad laptop running DWM as the window manager.
Entry points: `flake.nix` → `configuration.nix` (system) + `home.nix` (user via Home Manager).
DWM is built from source at `dwm/` and patched directly — no upstream pull, edit `dwm/config.def.h` for keybinds/colors.

Apply changes:
```sh
sudo nixos-rebuild switch --flake .#nixdan   # system
home-manager switch --flake .#nixdan         # user (home.nix)
```

---

## State after last session

### DWM patches applied (all in `dwm/dwm.c`, source patches in `dwm/patches/`)
| Patch | What it does |
|---|---|
| autostart | runs `~/.dwm/autostart.sh` on launch |
| alwayscenter | floating windows spawn centered |
| attachbottom | new windows go to bottom of stack, not master |
| systray | system tray in the bar |
| gaps (manual) | 8px gaps between windows in tile + monocle |
| movestack (manual) | `Mod+Shift+J/K` reorders windows in stack |

### Colors — ThinkPad palette (`dwm/config.def.h`)
- Background: `#1a1a1a`, inactive border: `#2d2d2d`, text: `#c0c0c0`
- Accent/selected: `#cc0000` (ThinkPad red), selected text: `#ffffff`
- Font: JetBrains Mono 10

### MODKEY changed from Alt → Super (Win key)

### Laptop hardware wired up (`configuration.nix`)
- Touchpad: natural scroll + tap-to-click via libinput
- Audio: PipeWire (wpctl for CLI volume in Fn keys)
- Bluetooth: `hardware.bluetooth` + `services.blueman`
- Backlight: `hardware.acpilight` + `brightnessctl`
- Power: TLP with 75–80% charge thresholds, thermald
- Multimonitor: `programs.autorandr` — first-time setup needed (see below)
- nm-applet: wifi icon in systray

### Autostart (`~/.dwm/autostart.sh`, managed via `home.nix`)
Launches: xsetroot wallpaper, nm-applet, blueman-applet, cheatsheet kitty window, status bar loop (battery + clock via xsetroot).

### Cheatsheet
- File: `~/.dwm/cheatsheet` (plain text, managed in `home.nix`)
- Opens automatically on boot into **tag 9** (`kitty --title "DWM Cheatsheet"`)
- Pinned to tag 9 via rule in `config.def.h`

---

## Things not yet done / follow-up needed

1. **Build and test** — nothing has been `nixos-rebuild switch`ed yet. This is all unapplied config.
2. **DWM compile check** — `dwm.c` has been patched manually; should verify it compiles:
   ```sh
   cd dwm && make 2>&1
   ```
3. **Multimonitor first-time setup** — after booting, plug in HDMI then:
   ```sh
   arandr           # drag monitors into position, File > Save As "docked"
   autorandr --save docked
   autorandr --save mobile   # with monitor unplugged
   ```
4. **Battery path** — status bar assumes `/sys/class/power_supply/BAT0/`. ThinkPads sometimes use `BAT1`. Check with `ls /sys/class/power_supply/` and fix in `home.nix` autostart if needed.
5. **pertag patch** — not applied yet. Would make each tag remember its own layout independently (very useful). Patch available at suckless.org.
6. **hide_vacant_tags** — not applied. Hides empty tag numbers from the bar (cleaner look).
7. **Wallpaper** — currently solid black via `xsetroot`. Could swap in `feh --bg-scale` for an image.
8. **Screenshots dir** — `scrot` saves to `~/Pictures/scrot/`. That directory needs to exist:
   ```sh
   mkdir -p ~/Pictures/scrot
   ```

---

## Key files
| File | Purpose |
|---|---|
| `flake.nix` | inputs + outputs, nixpkgs 26.05 |
| `configuration.nix` | system config — hardware, services, X11 |
| `hardware-configuration.nix` | auto-generated, don't touch |
| `home.nix` | user packages, dunst, fonts, autostart, cheatsheet |
| `dwm/config.def.h` | **all DWM keybinds, colors, rules** — edit this |
| `dwm/dwm.c` | patched DWM source |
| `dwm/patches/` | original .diff files (already applied, kept for reference) |
