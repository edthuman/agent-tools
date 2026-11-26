# Claude Flashing Notification

When Claude Code finishes or needs input in a terminal window you are not currently focused on, it's not always clear when it has finished doing what you asked of it.

This script allows iTerm2 windows that needs your attention to flash.

As soon as you focus the flashing window, its original background colour is restored.

## Requirements

- **macOS** with **iTerm2**
- **bash**

Other terminal apps are not supported. The script uses AppleScript to detect iTerm2's focus and background colour, so in any other terminal it cannot tell whether you are looking at the window and will flash regardless. This script may form a solid basis for a script that works for other terminals.

## Installation

In order to get the window to flash, you need to wire `flash.sh` into Claude Code's hooks in a `settings.json` like so, replacing `<PROJECT_ROOT>` with the appropriate value:

```json
{
  "hooks": {
    "Notification": [
      {
        "hooks": [
          { "type": "command", "command": "<PROJECT_ROOT>/flashing-notification/flash.sh" }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "<PROJECT_ROOT>/flashing-notification/flash.sh" }
        ]
      }
    ]
  }
}
```

`Notification` fires when Claude Code needs your attention (for example, a permission prompt) and `Stop` fires when it finishes responding. You may attach the script to either or both.

The script forks into the background and returns immediately, so it will not hold up Claude Code.

### macOS permissions

The script uses AppleScript to check which iTerm2 window is in focus. The first time it runs, macOS may ask you to allow automation of iTerm2 and System Events. These must be allowed for the script to work.

## Scope

The scope of the `settings.json` file you add the hooks to dictates which projects' Claude Code sessions will flash.

To add it to all Claude Code sessions, add the hooks to a global `.claude/settings.json`.

You may also add them to `.claude/settings.json` or `.claude/settings.local.json` within a folder to only apply them to a specific project, or any projects nested within the chosen folder.

To flash a different colour for different projects, see [Different colours per project](#different-colours-per-project).

## How it works

- The script walks up the process tree to find the terminal device Claude Code is running in, so it flashes the window that launched the session rather than whichever window is at the front.
- The script will do nothing if triggered while the terminal window is already focused.
- The original background colour is read from iTerm2 before the flash begins. If it cannot be detected, a fallback colour is used instead.
- Only one instance of flashing will run per terminal at a time. If it is triggered again while already flashing, the extra run is ignored. This is tracked with a lock file at `/tmp/cc-flash-<tty>.lock`, which is safe to delete if one is ever left behind.
- The original colour is restored whenever the script exits, including if it is stopped with `kill`, `pkill` or Ctrl+C.

> [!NOTE]  
> A forced `kill -9` cannot be intercepted, so the colour would stay stuck on the flash colour. To reset it manually, run `printf '\033]11;#RRGGBB\007'` in the affected window, replacing `#RRGGBB` with your terminal's normal background colour as a hex code (for example `#1D1D1D`), or open a new session.

## Customisation

All of the below options can be set near the top of `flash.sh`.

| Variable              | Default   | Description |
|-----------------------|-----------|-------------|
| `FLASH_COLOR`         | `#D48B77` | Colour shown during the flash |
| `FALLBACK_ORIG_COLOR` | `#1D1D1D` | Background colour restored if the window's original background colour could not be detected. Set this to match your theme's background |
| `FLASH_ON_SECS`       | `0.3`     | Seconds the flash colour is shown per cycle |
| `FLASH_OFF_SECS`      | `0.5`     | Seconds the original colour is shown per cycle |
| `TOTAL_FLASH_SECS`    | `10`      | Seconds of flashing before the window is held on the flash colour until you focus it |

The same colour is used for every notification. Passing a colour as an argument, for example from the command in `settings.json`, is not supported.

### Different colours per project

Because `FLASH_COLOR` is fixed in the script, the provided script uses the same flash colour for every project. If you want different projects to flash different colours, the script will need to be modified. You could either:

- Add argument handling to `flash.sh` so a colour can be passed in the command within each project's `settings.json`.
- Make separate copies of `flash.sh`, changing `FLASH_COLOR` in each copy, and point each project's `settings.json` at the relevant copy (see [Scope](#scope)).
