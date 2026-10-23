# world-clock

A polybar clock that cycles through time zones when you click it.

![screenshot](screenshot.png)

- **Left click**: next time zone
- **Middle click**: show or hide the full date
- Clicks update the clock immediately
- Daylight saving time is handled for you; labels can be anything, e.g. city names in any language

Plain POSIX `sh`: needs no bash, only `date` and `sleep`.

## Install

**1. Download the script** into your polybar scripts folder and make it executable:

```sh
mkdir -p ~/.config/polybar/scripts
curl -fLo ~/.config/polybar/scripts/world-clock.sh https://raw.githubusercontent.com/tipharez-allmighty/polybar-world-clock/main/world-clock.sh
chmod +x ~/.config/polybar/scripts/world-clock.sh
```

**2. Add the module** to your polybar config (usually `~/.config/polybar/config.ini`), with your own zones and labels:

```ini
[module/world-clock]
type = custom/script
exec = ~/.config/polybar/scripts/world-clock.sh "Asia/Taipei:臺北" "Europe/Paris:巴黎" "Europe/Kyiv:基輔"
tail = true
click-left = kill -USR1 %pid%
click-middle = kill -USR2 %pid%
```

`tail = true` is required: the script keeps running and polybar passes its PID as `%pid%`.

**3. Put it on your bar** by adding `world-clock` to `modules-left`, `modules-center` or `modules-right` in your `[bar/...]` section, e.g.:

```ini
modules-right = cpu memory world-clock
```

**4. Restart polybar**, e.g. by running your launch script again (or `polybar-msg cmd restart` if your bar has `enable-ipc = true`).

To check your zones before adding them, run the script in a terminal; it prints the first zone, or an error for a mistyped one (Ctrl+C to stop):

```sh
~/.config/polybar/scripts/world-clock.sh Europe/Paris America/New_York
```

## Options

```
world-clock.sh [-s FORMAT] [-l FORMAT] [-i SECONDS] ZONE[:LABEL]...
```

| Argument | Meaning | Default |
|---|---|---|
| `ZONE` | An IANA time zone, e.g. `Europe/Paris` (see `timedatectl list-timezones`), or a POSIX TZ string such as `UTC-0` or `CET-1CEST` | |
| `LABEL` | Text shown after the time | city part of the zone, e.g. `Paris` |
| `-s FORMAT` | Short format, shown by default | `%a %H:%M` |
| `-l FORMAT` | Long format, shown after a middle click | `%a %d.%m.%y %H:%M` |
| `-i SECONDS` | How often to refresh | `5` |

Formats use `date` syntax (see `man date`). Weekday and month names follow your locale (`LC_TIME`).

The first zone is shown at start.

Zones are checked at start: a typo like `Europe/Pari` prints `world-clock: unknown zone 'Europe/Pari'` on the bar,
instead of `date` silently showing UTC under your label. Zone files are looked up in `$TZDIR` if set,
otherwise in `/usr/share/zoneinfo`.

### Examples

```ini
; labels default to city names: "Sat 01:52 Taipei"
exec = ~/.config/polybar/scripts/world-clock.sh Asia/Taipei Europe/London America/New_York

; 12-hour clock, ISO date when expanded
exec = ~/.config/polybar/scripts/world-clock.sh -s "%I:%M %p" -l "%F %I:%M %p" Asia/Tokyo:Tokyo UTC:UTC
```

## Signals

You can drive the clock from anything, not just polybar clicks:

| Signal | Effect |
|---|---|
| `USR1` | Next time zone |
| `USR2` | Toggle short / long format |

```sh
pkill -USR1 -f world-clock.sh
```

## License

MIT, see [LICENSE](LICENSE).
