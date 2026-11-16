---
name: macos-disk-space
description: Find what fills a Mac's disk and free space safely, biggest safe win first, with a reference file per category of space user. Covers measuring free space on the Data volume, sizing folders without trusting `du` for APFS clones, finding paths that move between macOS and app versions by discovery rules rather than fixed lists, and the categories that usually hold the space - browsers (Chromium code-signing clones), programming (Rust `target/`, JetBrains caches, Homebrew, language caches, Docker and OrbStack) and Nix (generations, garbage collection, VMs). Use it when a Mac is low on disk space, when the user asks what can be deleted, or before deleting any cache or build folder.
---

# Free disk space on macOS

## Measure first

- **Read free space from the Data volume:** `df -k /System/Volumes/Data`.
  `/` is the sealed system volume, and on some macOS versions it reports a
  fixed small "used" figure that isn't the disk.
- **Record the free KiB before each deletion and after it.** The difference
  is the only true measure of what a deletion freed.
- **Size with `du -xsh`, one level at a time,** largest branch first:
  `~/Library/Caches`, `~/Library/Application Support`, the home folders,
  `/Applications`, then the per-user temp folder (see
  [Discovery rules](#discovery-rules)). A full `du` of a large home folder
  can take over 10 minutes, so run it in the background.

## `du` overstates APFS clones

APFS clones (`cp -c`, and what many apps make of themselves) share blocks
with their source until either is changed. `du` counts every clone in full,
so deleting a clone can free a small part of what `du` showed, or almost
nothing. Report such a folder's size as nominal, and its gain as unknown
until `df` is read after deleting. Browser code-signing clones, Nix store
copies and per-project dependency folders are common cases.

## Discovery rules

Paths move between macOS versions and app versions, so find them on the
machine rather than trusting a fixed list:

| To find                     | Read                                                                                    |
| --------------------------- | --------------------------------------------------------------------------------------- |
| the per-user temp folder    | `getconf DARWIN_USER_TEMP_DIR`; its sibling `../C` is caches and `../X` is code signing |
| an app's caches             | `~/Library/Caches/<bundle id or vendor>`, sized with `du -xsh ~/Library/Caches/*`       |
| an app's settings and data  | `~/Library/Application Support/<vendor>` and `~/Library/Containers/<bundle id>`         |
| which version an app runs   | `defaults read "/Applications/<App>.app/Contents/Info" CFBundleShortVersionString`      |
| whether a folder is in use  | `lsof +D <folder>`: exit 1 with no output means nothing is open                         |
| a tool's own cache location | the tool itself, such as `pip3 cache dir` or `go env GOCACHE`                           |

A category's reference file lists what it has found on each OS and app
version, and a rule to rediscover it when the version changes.

## Deleting

- **Prefer the owning tool's cleanup command** (`brew cleanup`,
  `pip3 cache purge`, `docker rmi`, `nix-collect-garbage`) over deleting its
  folders.
- **Name each path.** Never delete by glob, by an unchecked variable or by a
  whole cache root. Write the exact paths to a list and delete from the list.
- **A safety hook may block `rm -rf` outside the working directory.** Then
  give the user the command, with every path written out, rather than
  working around the hook.
- **Moving to the Trash frees nothing** until the Trash is emptied.
- **Check what a deletion takes besides cache.** A JetBrains cache folder,
  for one, also holds that IDE version's Local History.
- **Ask before anything that only the user can judge:** their files, app
  data, VM images, installed apps.

## Categories

Read the reference for each category the measurements point at:

- [Browsers](references/browsers.md): Chromium code-signing clones.
- [Programming](references/programming.md): Rust `target/` folders,
  JetBrains caches, Homebrew, language package caches, Docker and OrbStack.
- [Nix](references/nix.md): system generations, garbage collection, and
  Nix inside VMs.

## When to apply

- The Mac is low on disk space, or the user asks what can be deleted.
- Before deleting any cache, build folder or app data to free space.
- A deletion freed much less than `du` showed.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `shell-hygiene-delete-named-paths`: deleting by named path, never by glob or whole tree.
- `shell-hygiene-no-machine-wide-changes`: asking before changes that reach beyond the user's own files.
