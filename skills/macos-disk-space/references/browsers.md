# Browsers

## Chromium code-signing clones

Chrome, Brave, Edge and other Chromium browsers make an APFS clone of their
own app bundle each time they launch, so the running copy stays valid while
an update is installed. The browser should delete its clone when it exits;
clones of launches that crashed or were killed stay behind and pile up.

| Where                                                                                     | Seen on                            |
| ----------------------------------------------------------------------------------------- | ---------------------------------- |
| `$(getconf DARWIN_USER_TEMP_DIR)/../X/<bundle id>.code_sign_clone/code_sign_clone.XXXXXX` | macOS 27.2; Chrome 157, Brave 1.99 |

Discovery rule: list `$(dirname "$(getconf DARWIN_USER_TEMP_DIR)")/X/` and
look for `*.code_sign_clone` folders.

- **The size is nominal.** Each clone shares most blocks with the installed
  app, so 90 clones can show as 51G in `du` and free far less. Measure the
  gain with `df`.
- **Delete only clones nothing has open.** Quit the browser, or check:
  `lsof +D <the .code_sign_clone folder>` lists the clone a running browser
  uses. Each child must match `code_sign_clone.` plus 6 characters and be
  owned by the user.
- **A running browser makes a new clone at once,** so list the clones to
  delete, check them, and delete from the list, not from a fresh listing.
- **Ask before quitting a browser the user or an agent is using.** Claude in
  Chrome stops when Chrome quits.
