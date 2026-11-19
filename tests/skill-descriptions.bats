#!/usr/bin/env bats
# The skills' frontmatter descriptions, read with yq's YAML parser. Claude
# Code's skill listing shows only the description and drops descriptions
# when the listing overflows, so a description leads with when to load the
# skill and stays short.

setup() {
  SKILLS="$BATS_TEST_DIRNAME/../skills"
}

@test "the Trash skill's description leads with when to load it and names its neighbour" {
  skill="$SKILLS/macos-hygiene-trash-for-ad-hoc-deletes/SKILL.md"
  run yq --front-matter=extract '.description' "$skill"
  [ "$status" -eq 0 ]
  [[ "$output" == "Load "* ]]
  [[ "$output" == *'`shell-hygiene-delete-named-paths`'* ]]
  run yq --front-matter=extract '.description | length' "$skill"
  [ "$status" -eq 0 ]
  [ "$output" -le 500 ]
}
