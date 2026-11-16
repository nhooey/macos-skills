#!/usr/bin/env bats
# macos-skills' argument parsing and what it hands to shellcheck and bats,
# against stubs of both exported as shell functions. Each stub appends its
# working directory and arguments to $STUB/log; $STUB/exit sets its status.

setup() {
  SCRIPT="$BATS_TEST_DIRNAME/../scripts/macos-skills"
  STUB=$(mktemp -d)
  REPO="$STUB/repo"
  mkdir -p "$REPO/skills/one/scripts" "$REPO/skills/two/scripts" "$REPO/scripts" "$REPO/tests"
  touch "$REPO/skills/one/scripts/a" "$REPO/skills/two/scripts/b" "$REPO/scripts/tool"
  : >"$STUB/log"
  echo 0 >"$STUB/exit"
  export STUB REPO
  unset PRJ_ROOT

  shellcheck() {
    echo "$PWD shellcheck $*" >>"$STUB/log"
    return "$(cat "$STUB/exit")"
  }
  bats() {
    echo "$PWD bats $*" >>"$STUB/log"
    return "$(cat "$STUB/exit")"
  }
  export -f shellcheck bats
}

teardown() {
  rm -rf "$STUB"
}

@test "--help lists every command and option" {
  run "$SCRIPT" --help
  [ "$status" -eq 0 ]
  for token in lint test all --root --help; do
    [[ "$output" == *"$token"* ]]
  done
}

@test "each command's --help prints its usage without running it" {
  for cmd in lint test all; do
    run "$SCRIPT" "$cmd" --help
    [ "$status" -eq 0 ]
    [[ "$output" == "Usage: macos-skills $cmd"* ]]
  done
  [ ! -s "$STUB/log" ]
}

@test "no command, an unknown command or an unknown option is a usage error" {
  run "$SCRIPT"
  [ "$status" -eq 2 ]
  [[ "$output" == *"no command given"* ]]
  run "$SCRIPT" deploy
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown command: deploy"* ]]
  run "$SCRIPT" --verbose lint
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown option: --verbose"* ]]
  [ ! -s "$STUB/log" ]
}

@test "lint and all refuse arguments; --root needs a value" {
  run "$SCRIPT" lint extra
  [ "$status" -eq 2 ]
  [[ "$output" == *"lint takes no arguments"* ]]
  run "$SCRIPT" all extra
  [ "$status" -eq 2 ]
  run "$SCRIPT" --root
  [ "$status" -eq 2 ]
  [[ "$output" == *"--root needs a directory"* ]]
  run "$SCRIPT" --root "$STUB/missing" lint
  [ "$status" -eq 2 ]
  [[ "$output" == *"not a directory: $STUB/missing"* ]]
}

@test "lint shellchecks the skills' scripts and scripts/ from the root" {
  run "$SCRIPT" --root "$REPO" lint
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB/log")" = "$REPO shellcheck skills/one/scripts/a skills/two/scripts/b scripts/tool" ]
}

@test "test runs bats over tests/, or passes its arguments through" {
  run "$SCRIPT" --root="$REPO" test
  [ "$status" -eq 0 ]
  run "$SCRIPT" --root "$REPO" test --filter fix tests/x.bats
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB/log")" = "$REPO bats tests
$REPO bats --filter fix tests/x.bats" ]
}

@test "the root defaults to \$PRJ_ROOT" {
  cd "$STUB"
  PRJ_ROOT="$REPO" run "$SCRIPT" test
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB/log")" = "$REPO bats tests" ]
}

@test "all stops at a failing lint and exits 1" {
  echo 1 >"$STUB/exit"
  run "$SCRIPT" --root "$REPO" all
  [ "$status" -eq 1 ]
  [ "$(cat "$STUB/log")" = "$REPO shellcheck skills/one/scripts/a skills/two/scripts/b scripts/tool" ]
}

@test "all runs lint, then test" {
  run "$SCRIPT" --root "$REPO" all
  [ "$status" -eq 0 ]
  [ "$(cat "$STUB/log")" = "$REPO shellcheck skills/one/scripts/a skills/two/scripts/b scripts/tool
$REPO bats tests" ]
}
