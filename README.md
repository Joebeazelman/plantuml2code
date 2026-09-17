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
