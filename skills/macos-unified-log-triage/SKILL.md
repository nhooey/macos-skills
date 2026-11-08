---
name: macos-unified-log-triage
description: Read macOS's unified log, crash reports and launchd job states to find real problems, without mistaking an empty query for a clean log or Apple's routine noise for a fault. Call the log tool as `/usr/bin/log`, since zsh's `log` builtin shadows it and its error is easy to hide; prove a query can return lines before trusting an empty result; count faults and errors by process; widen time windows past one second; and set aside the errors Apple's own daemons log by the tens of thousands, idle services stopped with -9, and CPU-use reports. Use it when asked to check a Mac's logs for problems, to find what triggered a dialog or a crash, or whenever a `log show` or `log stream` query comes back empty.
---

# Triage macOS's unified log

## Call the tool as `/usr/bin/log`

In zsh, `log` is a shell builtin (it lists logins, for `watch`), so
`log show …` never reaches macOS's log tool: it prints `log: too many
arguments` to stderr and nothing to stdout. With `2>/dev/null` on the
command, that looks exactly like a log with no matching entries. Always
write `/usr/bin/log show` and `/usr/bin/log stream`, in every shell.

## Prove a query can find something

An empty result means nothing until the same command has found something:

1. **Run it once with no predicate** over the last minute:
   `/usr/bin/log show --last 1m --style compact | head -3` must print lines.
2. **Keep stderr** while building a predicate. A predicate with a typo or
   an unknown key fails on stderr, and hiding it turns the failure into
   silence.
3. **Widen time windows.** `--start` and `--end` take whole seconds, and
   a burst that falls inside one second can land outside a window drawn
   around it. Leave a few seconds on each side, and let entries settle
   for a second or two before reading a window that just ended.

## Count before reading

The log holds tens of thousands of errors an hour on a healthy Mac, so
read counts by process first, then the messages of the processes that
stand out:

```bash
/usr/bin/log show --last 1h --predicate 'messageType == fault' --style ndjson |
  python3 -I -c '
import sys, json, collections
c = collections.Counter()
for line in sys.stdin:
    try: c[json.loads(line).get("processImagePath", "").rsplit("/", 1)[-1]] += 1
    except ValueError: pass
for p, n in c.most_common(15): print(f"{n:7} {p}")'
```

Use `messageType == error` for errors. Then read one process's messages
with `--predicate 'process == "<name>"'`, which shows the lines around
each error.

## Routine noise

These show up on any Mac and are not problems on their own:

| What                                                   | Why it's routine                                                                                                                                                   |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Errors from Apple daemons by the thousands an hour     | `cfprefsd` missing preference files, `mediaanalysisd` and `intelligenceflowd` missing streams, `runningboardd` memory-limit calls, `WindowServer` run-loop lookups |
| `syspolicyd`: `cannot open file at line … of [<hash>]` | Gatekeeper checks a program it hasn't seen, such as a new build, and SQLite fails to open `/private/var/db/DetachedSignatures`, which isn't there; no CPU cost     |
| Faults about entitlements, identities and CFPrefs      | `apsd`, `runningboardd`, `biomesyncd`, `imagent` and others report them steadily                                                                                   |
| `launchctl list` showing `-9` for `com.apple.*` jobs   | launchd stops idle Apple services with SIGKILL to free memory, and starts them again on demand                                                                     |
| `*.cpu_resource.diag` reports                          | macOS notes a daemon that used a lot of CPU for a while, such as Spotlight's `spotlightknowledged` while indexing                                                  |

Read routine noise only when the user's problem is in that daemon: a
Spotlight problem makes `spotlightknowledged`'s reports relevant.

## What is worth acting on

- **Crash reports** for apps that aren't Apple's:
  `~/Library/Logs/DiagnosticReports/*.ips` and
  `/Library/Logs/DiagnosticReports/`. The first line is a JSON header
  with the app's name and version; the `exception` and `termination`
  fields give the signal. Report filenames hold spaces: quote them.
- **Faults and errors from non-Apple processes**, and from the user's own
  daemons and agents, whose logs may also live in `~/Library/Logs/`.
- **launchd jobs that aren't Apple's with a positive exit code:**
  `launchctl list | awk 'NR>1 && $2 > 0 && $3 !~ /^com[.]apple[.]/'`.
- **A count that changed:** the same error at many times its usual rate,
  or one that started at a known time, such as after an update.

## When to apply

- Asked to check a Mac's logs for problems, or why something crashed.
- Looking for what triggered a dialog, a prompt or a crash at a known time.
- A `log show` or `log stream` query returns nothing.
