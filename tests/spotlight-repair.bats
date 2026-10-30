#!/usr/bin/env bats
# spotlight-repair against stubs of the macOS commands it runs, exported as
# shell functions, and app folders in a temporary directory. $STUB holds the
# stubs' state: data-state (the Data volume's mdutil state line), indexed (the
# paths mdfind returns), mds-pid, and log (what sudo, kill and mdimport did).

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../skills/macos-spotlight-repair/scripts/spotlight-repair"
  STUB=$(mktemp -d)
  APPS="$STUB/Applications"
  mkdir -p "$APPS/One.app" "$APPS/Two.app"
  printf '%s\n' "$APPS/One.app" "$APPS/Two.app" >"$STUB/indexed"
  echo "Indexing enabled." >"$STUB/data-state"
  echo 100 >"$STUB/mds-pid"
  : >"$STUB/log"
  export STUB APPS
  export SPOTLIGHT_DATA_VOLUME="$STUB" SPOTLIGHT_APP_DIRS="$APPS" SPOTLIGHT_WAIT=3

  mdutil() {
    printf '%s:\n' "$2"
    if [ "$2" = "$STUB" ]; then printf '\t%s\n' "$(cat "$STUB/data-state")"; else printf '\tIndexing enabled. \n'; fi
  }
  mdfind() { cat "$STUB/indexed"; }
  pgrep() { cat "$STUB/mds-pid"; }
  sudo() { echo "sudo $*" >>"$STUB/log"; "$@"; }
  # A new mds loads the Data volume's index, as the real one did.
  kill() {
    echo "kill $*" >>"$STUB/log"
    echo 200 >"$STUB/mds-pid"
    echo "Indexing enabled." >"$STUB/data-state"
  }
  mdimport() {
    echo "mdimport $*" >>"$STUB/log"
    echo "$1" >>"$STUB/indexed"
  }
  sleep() { :; }
  export -f mdutil mdfind pgrep sudo kill mdimport sleep
}

teardown() {
  rm -r "$STUB"
}

@test "check passes when the Data volume is enabled and every app is indexed" {
  run "$SCRIPT" check
  [ "$status" -eq 0 ]
  [[ "$output" == *"$STUB: Indexing enabled."* ]]
  [[ "$output" == *"Spotlight finds every app."* ]]
}

@test "check fails and names the volume state and the missing apps" {
  echo "Error: unknown indexing state." >"$STUB/data-state"
  echo "$APPS/One.app" >"$STUB/indexed"
  run "$SCRIPT" check
  [ "$status" -eq 1 ]
  [[ "$output" == *"$STUB: Error: unknown indexing state."* ]]
  [[ "$output" == *"  $APPS/Two.app"* ]]
  [[ "$output" != *"  $APPS/One.app"* ]]
}

@test "check never runs sudo, kill or mdimport" {
  echo "Error: unknown indexing state." >"$STUB/data-state"
  run "$SCRIPT" check
  [ ! -s "$STUB/log" ]
}

@test "fix restarts mds by PID, imports the missing app and ends healthy" {
  echo "Error: unknown indexing state." >"$STUB/data-state"
  echo "$APPS/One.app" >"$STUB/indexed"
  run "$SCRIPT" fix
  [ "$status" -eq 0 ]
  grep -qx "sudo kill 100" "$STUB/log"
  grep -qx "mdimport $APPS/Two.app" "$STUB/log"
  [[ "$output" == *"mds is back (PID 200)."* ]]
  [[ "$output" == *"Spotlight finds every app."* ]]
}

@test "fix only imports when the Data volume is already enabled" {
  echo "$APPS/One.app" >"$STUB/indexed"
  run "$SCRIPT" fix
  [ "$status" -eq 0 ]
  ! grep -q kill "$STUB/log"
  grep -qx "mdimport $APPS/Two.app" "$STUB/log"
}

@test "fix points to rebuild when restarting mds doesn't help" {
  echo "Error: unknown indexing state." >"$STUB/data-state"
  kill() { echo "kill $*" >>"$STUB/log"; echo 200 >"$STUB/mds-pid"; }
  export -f kill
  run "$SCRIPT" fix
  [ "$status" -eq 1 ]
  [[ "$output" == *"rebuild"* ]]
  ! grep -q mdimport "$STUB/log"
}

@test "import with no missing apps imports nothing" {
  run "$SCRIPT" import
  [ "$status" -eq 0 ]
  [[ "$output" == "Nothing to import." ]]
}

@test "rebuild erases the Data volume's index, never the system volume's" {
  mdutil() { echo "mdutil $*" >>"$STUB/log"; }
  export -f mdutil
  run "$SCRIPT" rebuild
  [ "$status" -eq 0 ]
  grep -qx "sudo mdutil -E $STUB" "$STUB/log"
}

@test "an unknown command prints the usage and exits 2" {
  run "$SCRIPT" bogus
  [ "$status" -eq 2 ]
  [[ "$output" == "Usage: spotlight-repair"* ]]
}
