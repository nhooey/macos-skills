# Nix

## The Mac's store

`/nix/store` holds every path a system generation, a profile or a GC root
needs, so it can only shrink as far as those roots allow.

- **Generations:** `ls -l /nix/var/nix/profiles/ | grep system-` lists
  nix-darwin's.
- **Scheduled cleanup:** nix-darwin's `org.nixos.nix-gc` job runs
  `nix-collect-garbage --delete-older-than <age>`; read its age with
  `plutil -p /Library/LaunchDaemons/org.nixos.nix-gc.plist`.
- **A one-off cleanup** with a shorter age needs `sudo` and frees what only
  older generations held. It can free little: per-project GC roots and the
  kept generations hold most of the store.
- **Rollback** past the age is gone after it runs, so ask first.

## Nix inside a VM

A NixOS machine in OrbStack or another VM keeps its own store, often much
larger than the Mac's.

- **Clean it inside:** `orb -m <machine> -u root nix-collect-garbage -d`,
  after checking no build runs there.
- **`-d` deletes every old generation** of that machine, so it can't roll
  back.
- **Measure inside and out:** `df -h /` in the machine, and `df -k` on the
  Mac once the VM's disk image has shrunk.
