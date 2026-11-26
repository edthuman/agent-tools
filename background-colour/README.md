# Terminal Background Colour

Commands that change the background colour of the current terminal window, with the ability to be run from within a Claude Code session.

| Command | Colour |
|---------|--------|
| `bgr` | red |
| `bgo` | orange |
| `bgy` | yellow |
| `bgg` | green |
| `bgb` | blue |
| `bgi` | indigo |
| `bgv` | violet |
| `bgd` | default terminal background |

<br>

![Terminal background colour samples](colours.svg)

## Installation

From the `background-colour/` folder:

```
./install.sh
```

This symlinks the commands into `~/.local/bin` (override with `BG_INSTALL_DIR`). The symlinks point at this repo, so `git pull` updates them. If `~/.local/bin` isn't on your `PATH`, the installer tells you what to add. Re-running it is safe.

## How it works

`bg.sh` writes an OSC 11 escape sequence to the controlling terminal (`/dev/tty`) to set the background, and OSC 111 to reset it to the profile default. Only the window you run it in changes. It works in iTerm2 and most modern terminals. `bg.sh red` also works directly.

Inside tmux/screen, escape sequences are not passed through by default, so it will not work there.

## Customisation

The shades are set at the top of `bg.sh` and can be adjusted to suit your theme. They are muted so light text stays readable on a dark theme.
