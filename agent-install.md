# Install afk on this machine

You are a coding agent installing afk (an SDLC spine and unattended loop for Claude Code and Codex) on the user's machine. Follow these steps in order. Keep your questions to the ones named here.

## 1. Get the CLI

Run `afk --version`, then `"$HOME/.local/bin/afk" --version`. afk is present if either succeeds.

- If both fail, install it: `curl -fsSL https://merchantlabs.github.io/afk-releases/install.sh | AFK_NO_SETUP=1 sh`. `AFK_NO_SETUP=1` stops the installer from prompting, because your shell cannot answer prompts.
- If either works, run `afk update` (or `"$HOME/.local/bin/afk" update` when only that one works) and never run install.sh. install.sh would overwrite a source-channel symlink, even one that is not on your PATH.

## 2. Call afk by its full path

From here on, call it as `"$HOME/.local/bin/afk"`. The PATH line the installer adds to the shell startup file is not in your already-running shell.

## 3. Pick the harnesses

Run `command -v claude codex`.

- One found: say which one you will install into and go on.
- Both found: ask which to install into (claude, codex or both).
- None found: stop and tell the user afk needs Claude Code or Codex.

## 4. The tailnet entry

Ask only when `command -v tailscale` succeeds and Claude Code is among the chosen harnesses. Otherwise skip the question and use no tailnet entry.

Explain in one sentence: Claude Code's auto mode blocks agents from exposing a dev or preview server on the tailnet, which is how `afk preview` serves, and the entry tells auto mode the tailnet is private to the user and allows `tailscale serve`, `*.ts.net` routes and tailnet-address binds (the tailnet only, never Funnel or a public bind). Ask whether to add it.

## 5. Warn about permissions

Before installing, tell the user the install writes outside the project (`~/.afk/`, `~/.local/bin/`, and the harness's own settings), so Codex will ask to escalate and Claude Code will ask for approval.

## 6. Install

Run this first, with the harness ids from step 3 (comma-separated):

```bash
"$HOME/.local/bin/afk" install --harness <ids> --no-tailnet
```

Then, only if the user said yes in step 4, run this as a separate command:

```bash
"$HOME/.local/bin/afk" install --harness claude --tailnet
```

If Claude Code's auto mode refuses the second command, do not try another route around the guard. Give the user that exact command to run themselves, prefixed with `!` in Claude Code.

## 7. Report the result

Report the doctor output that `install` ends with, and explain each failing row. The "hooks have not run yet" warning is expected until the harness restarts.

## 8. Hand back to the user

Tell the user to:

1. Restart the harness. On Codex, also approve afk's hooks in `/hooks`.
2. Open a new session in their project.
3. Run `afk doctor` there and confirm every row is ok.
4. Run `/afk:setup`.

Never restart a session yourself.
