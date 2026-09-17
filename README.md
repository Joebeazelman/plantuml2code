# plantuml2code

A workspace of three Ada crates that parse PlantUML state and class
diagrams and generate Ada code from them.

## Crates

- **`plantuml_parser`** — library. Parses PlantUML diagrams into a
  structured model with regions, states, transitions, annotations,
  guards, and effects.
- **`hsm_runtime`** — library. Generic hierarchical state machine
  engine used by the generated code.
- **`plantuml2code`** — application. CLI that reads a `.puml` file and
  emits text, JSON, or Ada HSM source.

`gen_test` is a sample project that consumes generated Ada and compiles
against `hsm_runtime`.

## Quick start

    cd plantuml_parser   && alr build
    cd ../hsm_runtime    && alr build
    cd ../plantuml2code  && alr build

    ./bin/plantuml2code dump ../samples/nested.puml
    ./bin/plantuml2code dump -f json ../samples/nested.puml
    ./bin/plantuml2code dump -f ada -o /tmp/gen ../samples/nested.puml

See `AGENTS.md` for architecture notes and known gotchas.

## Publishing

`plantuml_parser` and `hsm_runtime` are both ready to publish to the
Alire community index. Their index manifests are committed under each
crate's `alire/releases/` directory:

- `plantuml_parser/alire/releases/plantuml_parser-0.1.0.toml`
- `hsm_runtime/alire/releases/hsm_runtime-0.1.0.toml`

To submit a new version:

    cd plantuml_parser && alr publish
    cd ../hsm_runtime && alr publish

Each opens a PR against `alire-project/alire-index`. Requires a GitHub
Personal Access Token configured for `alr`; see
https://github.com/alire-project/alire/blob/master/doc/publishing.md

Publishing is deferred until there is a reason to (first outside user,
or a feature-complete milestone).
