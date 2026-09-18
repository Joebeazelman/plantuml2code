# Publishing to the Alire community index

Both `plantuml_parser` and `hsm_runtime` are ready to submit. The
index manifests are committed under each crate's `alire/releases/`
directory. Nothing needs to change in the source to publish — the
setup below is one-time, and the actual submission is one command
per crate.

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
    cd ../hsm_runtime  && alr publish --skip-submit

Both should print a summary and generate a manifest under
`<crate>/alire/releases/`. If they succeed, the crates are
publishable as-is.

## Submitting

When you decide to go live:

    ./publish.sh

That script publishes both crates in sequence. Each one:

1. Forks `alire-project/alire-index` (or uses your existing fork).
2. Adds the manifest at `index/<two-letter-prefix>/<crate>/`.
3. Opens a PR against the community index.

Prefixes: `plantuml_parser` goes under `index/pl/`, `hsm_runtime`
under `index/hs/`.

## What the moderators will check

Expect a review before merge. Common requests:

- LICENSE file present at the crate root. **Currently missing** — see
  the "Before submitting" section below.
- Description and tags match the crate's purpose.
- `maintainers-logins` matches the GitHub account opening the PR.
- Build passes from a clean environment.

## Before submitting

Two things are worth doing immediately before the first submission:

1. **Add a LICENSE file.** Alire checks for one at the crate root,
   and both crates declare "MIT OR Apache-2.0 WITH LLVM-exception".
   Create the file(s) once with the text of both licenses.

2. **Run `./publish.sh --check`** to see whether anything else in the
   manifests has drifted since the last `--skip-submit` run.

## Reverting a submission

If a PR needs to be withdrawn:

    alr publish --cancel <PR-number> --reason "short reason"

Or close the PR on GitHub directly. The index maintainers can also
do this on request.
