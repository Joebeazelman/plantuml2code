# uml2code

Parse PlantUML state and class diagrams into a normalized model, then
generate Ada 2022 code from that model. Two-crate workspace, built
with Alire.

## Crates

- **`plantuml_parser`** — library. Tokenizer, PlantUML state and class
  parsers, and the normalized `UML.Model` they both target.
- **`uml2code`** — application. CLI that reads a `.puml` file and
  emits text, JSON, or Ada.

## Quick start

    cd plantuml_parser && alr build
    cd ../uml2code && alr build

    cd uml2code
    ./bin/uml2code gen ../samples/nested.puml
    ./bin/uml2code gen -f json ../samples/nested.puml
    ./bin/uml2code gen -f ada -o /tmp/gen ../samples/nested.puml
    bash /tmp/gen/setup.sh

The last command builds and runs the generated project.

## Configuration

Template location is resolved in this order:

1. `-t <dir>` on the command line
2. `./uml2code.conf` (project config)
3. `~/.config/uml2code/config` (home config)
4. `$UML2CODE_TEMPLATES`
5. Built-in `resources/templates` lookups relative to the crate

Config files use a flat `key = value` format; only `templates_dir` is
recognised. Comment lines start with `#`.

    # uml2code.conf
    templates_dir = /path/to/my/templates

## Templates

Templates live under `resources/templates/<format>/<diagram-kind>/`.
Formats: `ada`, `json`. Kinds: `state`, `class`. Runtime and project
scaffolding templates live at the format level and are shared across
kinds:

    resources/templates/
      ada/
        state/     state.ads.tmplt, state.adb.tmplt, actions.*
        class/     class.ads.tmplt, class.adb.tmplt, class_operations.*
        runtime/   state_machine.*
        project/   driver.adb.tmplt, setup.sh.tmplt
      json/
        state/, class/

## Tests

    cd plantuml_parser && ./run_tests.sh    # AUnit
    cd ../uml2code && ./run_tests.sh   # AUnit
    cd .. && ./tests/run_tests.sh           # golden files

Golden files compare every generated `.ads`/`.adb`/`driver.adb`
against `tests/golden/<case>/`. Update with `./tests/update_golden.sh`
after an intentional output change.

## Publishing

`plantuml_parser` is ready to publish. See `PUBLISHING.md`.

## Further reading

`AGENTS.md` documents architecture, the template tag protocol, and the
roadmap.
