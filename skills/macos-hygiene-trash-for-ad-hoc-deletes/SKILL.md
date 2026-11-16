---
name: macos-hygiene-trash-for-ad-hoc-deletes
description: On macOS, move the files and folders you delete yourself to the Trash with `/usr/bin/trash --verbose --stopOnError <paths>`, so the user can still recover them, instead of `rm` or a hand-made move into `~/.Trash`. Covers listing and naming each path first, the two cases where `rm` is right (space that must be reclaimed now, and throwaway paths you created), and keeping repository code portable, never detecting macOS to call `trash`. Use it on macOS whenever you are about to delete files or folders yourself, as cleanup during a session, outside repository code.
---

# Send ad-hoc deletes to the Trash on macOS

_On macOS, what you delete yourself goes to the Trash, named path by named
path._

When you delete something yourself on macOS, as cleanup during a session
rather than in code, move the named paths to the Trash, so the user can
still recover them:

```bash
/usr/bin/trash --verbose --stopOnError build/old-report.html notes.tmp
```

- **`--verbose`:** prints each path as it goes, so the user sees what moved.
- **`--stopOnError`:** stops at the first path that fails, rather than
  moving the rest.

Don't use `rm` for these, and don't move files into `~/.Trash` by hand.
List first and name each path, as for any other delete.

## When `rm` is right instead

Use `rm` on the named paths, and say which reason applies, when:

- **Space has to be reclaimed now:** large build outputs, or a full disk.
- **The path is throwaway:** it is in the session's scratch directory, or
  another throwaway directory you created.

## Never in repository code

This is for your own ad-hoc work only. Scripts, Makefiles, dev shell
commands and anything else committed to a repository stay portable: they
`rm` named paths, and never detect macOS to call `trash`.

## When to apply

- On macOS, about to delete files or folders yourself, outside repository
  code.
- Cleaning up at the end of a task on macOS.

## Your preferences

!`cat "${CLAUDE_SKILL_DIR}/../macos-hygiene-trash-for-ad-hoc-deletes.preferences.md" "${CLAUDE_PROJECT_DIR}/.agents/skills/macos-hygiene-trash-for-ad-hoc-deletes.preferences.md" 2>/dev/null || true`

If your agent doesn't run the line above, read these files yourself if they
exist: `macos-hygiene-trash-for-ad-hoc-deletes.preferences.md` next to this
skill's folder, then
`.agents/skills/macos-hygiene-trash-for-ad-hoc-deletes.preferences.md` in
the project. A project's file overrides the user's, and the user's
overrides this skill's defaults.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `shell-hygiene-delete-named-paths`: which paths a delete may name, listing them first, and the narrower command for each broad one.
