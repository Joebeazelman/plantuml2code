# Publishing to the Alire community index

`plantuml_parser` is ready to submit. Its index manifest is committed
under `plantuml_parser/alire/releases/`. Nothing needs to change in
the source to publish — the setup below is one-time, and the actual
submission is one command.

## Prerequisites

- A GitHub Personal Access Token (classic) with `repo` and `workflow`
  scope. Create one at https://github.com/settings/tokens.
- The `alr` tool already authenticated (it uses the token above).

## One-time setup

    alr settings --global --set github_login Joebeazelman
    alr settings --global --set github_token <paste-token-here>

This stores the credentials in `~/.config/alire/settings.toml`. If
you'd rather not persist the token, export it per-session instead:

    export GH_TOKEN=<paste-token-here>

## Verify readiness without submitting

`alr publish` in Alire 2.1.1 has no `--dry-run` flag. The equivalent
is `--skip-submit`, which runs every check (including a full build)
but does not open a PR:

    cd plantuml_parser && alr publish --skip-submit

This prints a summary and regenerates a manifest under
`plantuml_parser/alire/releases/`. If it succeeds, the crate is
publishable as-is.

## Submitting

When you decide to go live:

    cd plantuml_parser && alr publish

This:

1. Forks `alire-project/alire-index` (or uses your existing fork).
2. Adds the manifest at `index/pl/plantuml_parser/`.
3. Opens a PR against the community index.

## What the moderators will check

Expect a review before merge. Common requests:

- LICENSE file present at the crate root. **Currently missing** — see
  the "Before submitting" section below.
- Description and tags match the crate's purpose.
- `maintainers-logins` matches the GitHub account opening the PR.
- Build passes from a clean environment.

## Before submitting

Two things are worth doing immediately before the first submission:

1. **Confirm the LICENSE file is at the crate root.** Alire checks
   for one, and `plantuml_parser` declares
   "MIT OR Apache-2.0 WITH LLVM-exception".

2. **Run `alr publish --skip-submit`** to see whether anything in
   the manifest has drifted since the last check.

## Reverting a submission

If a PR needs to be withdrawn:

    alr publish --cancel <PR-number> --reason "short reason"

Or close the PR on GitHub directly. The index maintainers can also
do this on request.
