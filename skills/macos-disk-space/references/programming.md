# Programming

## Rust `target/` folders

Build output inside each repo, often the largest item on a developer's
Mac: 1 to 40G per repo, rebuilt by the next `cargo build`.

- **Find them:** `find <code roots> -maxdepth 5 -type d -name target -prune`,
  keeping only those with a sibling `Cargo.toml`.
- **Judge idleness by** `stat -f '%Sm' -t '%Y-%m-%d' <repo>/target/debug`.
- **Skip a repo** with a `cargo` or `rustc` running, or one a live service or
  agent session builds from.

## JetBrains IDEs

Each IDE version gets its own folders, and old versions' folders stay after
an upgrade:

| Where                                                        | Holds                                     |
| ------------------------------------------------------------ | ----------------------------------------- |
| `~/Library/Caches/JetBrains/<Product><version>`              | indexes, and that version's Local History |
| `~/Library/Logs/JetBrains/<Product><version>`                | logs                                      |
| `~/Library/Application Support/JetBrains/<Product><version>` | settings and plugins                      |

Discovery rule: compare the folder versions with each installed IDE's
`CFBundleShortVersionString`. A folder older than the installed version
belongs to a version no longer run. Its cache can go, but its Local History
goes with it, so say so. Settings folders aren't caches; the installed
version imports them once.

## Homebrew

`brew cleanup --prune=all` deletes every downloaded bottle and cask in
`~/Library/Caches/Homebrew`; `brew cleanup -n --prune=all` shows the size
first. Installed apps stay.

## Language package caches

| Tool   | Cleanup                                 | When the tool isn't on PATH        |
| ------ | --------------------------------------- | ---------------------------------- |
| pip    | `pip3 cache purge`                      | delete `pip3 cache dir`'s folder   |
| Go     | `go clean -cache`                       | delete `~/Library/Caches/go-build` |
| Poetry | `poetry cache clear --all <cache name>` | delete `~/Library/Caches/pypoetry` |

In a Nix setup, `go` and `poetry` are often only in project dev shells.

## Docker and OrbStack

On OrbStack 2.2, `~/OrbStack` is OrbStack's live view into its machines
and Docker, not ordinary folders: delete through `docker` and `orb`, never
in Finder.

- **Docker:** `docker system df` shows what is unused; remove images by
  name with `docker rmi <repo:tag>`, keeping every image a container uses
  (`docker ps -a`).
- **Machines:** `orb list` shows each machine's size. A Nix machine is
  cleaned from inside, as [Nix](nix.md) says.
- **The Mac gets the space back** as OrbStack's disk image shrinks, which
  `df` shows.
