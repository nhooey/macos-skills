---
name: macos-spotlight-repair
description: Find out why Spotlight on macOS can't find an app or file, and repair its index mildest step first, with the bundled scripts/spotlight-repair. Covers reading each volume's indexing state, listing the apps Spotlight misses, restarting Spotlight's server when SIP refuses `launchctl kickstart`, re-importing apps with mdimport, and rebuilding the Data volume's index, the one that holds /Applications. Use it when Spotlight or `mdfind` misses an installed app, when `mdutil -s` says "unknown indexing state" or `mdutil -i on` fails with -405, or when an `mdutil -E /` rebuild changed nothing.
---

# Repair Spotlight's index on macOS

Since macOS 10.15 the disk has two volumes: the read-only system volume at
`/`, and the Data volume at `/System/Volumes/Data`, which holds
`/Applications`, the home folders and everything else that changes. Each has
its own Spotlight index. So when Spotlight misses an app:

- **Check the Data volume.** `mdutil -s /` can say "Indexing enabled." while
  `mdutil -s /System/Volumes/Data` says "Error: unknown indexing state.";
  only the second matters for `/Applications`.
- **`mdutil -E /` does nothing for it.** It rebuilds the system volume's
  index, returns at once, and leaves the Data volume's as it was.
- **A broken Data index refuses new imports.** `mdimport` reports success,
  but nothing reaches the index until Spotlight's server, `mds`, reloads it.

## The script

`scripts/spotlight-repair`, in bash, with only the commands macOS ships:

| Command               | Does                                                                                    | Needs sudo    |
| --------------------- | --------------------------------------------------------------------------------------- | ------------- |
| `check` (the default) | prints each volume's state and the apps Spotlight can't find; exits 1 if anything's off | no            |
| `fix`                 | `check`, then `restart` if the Data volume isn't enabled, then `import`, then `check`   | for `restart` |
| `restart`             | ends `mds` by its PID; launchd starts a new one, which reloads the indexes              | yes           |
| `import [PATH...]`    | `mdimport`s the given paths, or with none, the missing apps                             | no            |
| `rebuild`             | `mdutil -E /System/Volumes/Data`: erases and rebuilds the Data volume's index           | yes           |

It checks the app bundles directly inside `/Applications`,
`/Applications/Utilities` and `~/Applications`.

## Repairing, mildest step first

1. **Run `spotlight-repair check`** yourself: it only reads.
2. **Ask the user to run `spotlight-repair fix`** in their own terminal.
   Restarting `mds` needs their `sudo` password and changes the whole
   machine, so it is theirs to run. While System Integrity Protection is
   on, launchctl refuses to restart `com.apple.metadata.mds` (error 150);
   ending the process works, and launchd restarts it at once.
3. **If `fix` says the index is still broken, ask them to run
   `spotlight-repair rebuild`.** Search results are incomplete until the
   rebuild finishes, which takes from minutes to hours on a full disk;
   `spotlight-repair check` shows when the state is "Indexing enabled." again.
4. **Restart the Mac only if the rebuild fails too.**

When the Data volume is enabled but one app stays missing after `import`,
the cause is that app, not the index: an exclusion under System Settings,
Spotlight, Search Privacy, or a bundle Spotlight won't index. `mdimport -t
-d1 <app>` shows what the importer reads from it.

## When to apply

- Spotlight or `mdfind` doesn't find an installed app, or finds fewer apps
  than `/Applications` holds.
- `mdutil -s` reports "unknown indexing state", or `mdutil -i on` fails
  with -405.
- Someone is about to restart a Mac only to fix Spotlight.
