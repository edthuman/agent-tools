# Claude Usage Tracker

Gradient progress bars for Claude Code's status line.

Each bar visualises one usage metric (session context, token rate limits, or spend) filling the progress bar with a colour gradient.

```
Context |################---------| 64%
Week    |########-----------------| 32%
```

## Requirements

These trackers should work with any terminal app or IDE-integrated terminal that has:
- **bash** (3.2+)
- **jq**

## True Colour

For optimal colour performance, your terminal will need to support true colour (24-bit RGB).

Terminals without this may still run the usage trackers, but the appearance of your status bars will likely be degraded. Colours seen may not match the hex codes used, and the gradients displayed can be less smooth.

## Installation

In order to get the status line to appear in your Claude Code sessions, you need to wire `statusline.sh` into Claude Code's `statusLine` hook in a `settings.json` like so, replacing <PROJECT_ROOT> and <ARGUMENTS> with the appropriate values:

```json
{
  "statusLine": {
    "type": "command",
    "command": "<PROJECT_ROOT>/usage-tracker/statusline.sh <ARGUMENTS>"
  }
}
```

Claude Code calls the script with the session JSON on stdin and displays whatever the script prints to stdout.

## Scope

The scope of the `settings.json` file you add the command to dictates which projects the status lines will be shown for.

To add it to all Claude Code sessions, add the command to a global `.claude/settings.json`.

You may also add it to `.claude/settings.json` or `.claude/settings.local.json` within a specific folder to only appear for a specific project, or any projects nested within the chosen folder.

## Arguments

```
statusline.sh '[MODE:LABEL]'...
```

Each argument becomes one bar. With no arguments a single unlabelled `SESSION` bar is printed.

| Part    | Description |
|---------|-------------|
| `MODE`  | Which metric to display (case-insensitive) |
| `LABEL` | Text shown beside the percentage (up to 20 characters) |

It is recommended that you pass arguments in single quotes to avoid unexpected behaviours. Double quotes work, but you will need to escape them using `\"` to pass your arguments as a command for a `settings.json` file. Quotes may be omitted entirely.

### Modes

| Mode       | Metric |
|------------|--------|
| `SESSION`  | Context window used (default) |
| `FIVEHOUR` | Five-hour rate limit |
| `WEEK`     | Seven-day rate limit |
| `SPEND`    | Spend limit |

Unrecognised values fall back to `SESSION`.

Some of these modes may not apply depending on your Claude Code account setup. If you are always seeing 0% for a particular mode, it may not apply for your account.

### Labels

Labels will be shown up to the first 20 characters. You can remove this truncation or change this limit by editing the below line in the output generator:

``` bash
label="${label:0:20}"
```

Emojis may be used in labels, but can lead to incorrect width of label calculations as this script intentionally uses a fast approximation. Incorrect width calculations can cause the status line to not take up the full terminal width or exceed it.

Leading whitespace is removed from rendered status lines shown in Claude Code. Trailing whitespace is rendered as passed.

### Examples

```bash
# Single unlabelled bar showing session context used
statusline.sh

# Single labelled bar showing session context used
statusline.sh 'SESSION:🤖'

# Two labelled bars showing context window and weekly rate limit
statusline.sh 'SESSION:Context' 'WEEK:Week'

# Four labelled bars
statusline.sh 'SESSION:Context' 'FIVEHOUR:5h' 'WEEK:Week' 'SPEND:Spend'
```

## Customisation

Both of the below options can be set near the top of `statusline.sh`.

### Gradient colours

`GRADIENT_COLORS` is an array of hex RGB strings spread evenly from 0 % to 100 %. The default goes green → yellow → red → purple → dark blue.

```bash
GRADIENT_COLORS=(
  "00ff00"   # green
  "ffff00"   # yellow
  "ff0000"   # red
  "800080"   # purple
  "00008b"   # dark blue
)
```

If you want a particular colour to appear longer in the gradient, you can put it in the array multiple times.

### Label alignment

`LABEL_ALIGN` controls where the label appears relative to the bar.

```bash
LABEL_ALIGN="LEFT"   # Label |####---| 75%
LABEL_ALIGN="RIGHT"  # |####---| Label 75%
```

## Resizing terminal
On resizing the terminal, you may find that the status lines are no longer the appropriate width. This will automatically fix itself.

You may force the status bars to refresh by using `Ctrl` + `C` - this will stop any in-progress work Claude Code is doing, and clears your input.