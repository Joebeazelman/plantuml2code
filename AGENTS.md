# plantuml2code — agent notes

A workspace of Ada crates that parse PlantUML diagrams and generate
Ada code from them. This document is the map; read it before making
changes.

## Layout

    plantuml_parser/    library — syntactic model of PlantUML state/class diagrams
    hsm_runtime/        library — generic hierarchical state machine engine
    plantuml2code/      application — CLI: text, json, ada output
    gen_test/           sample — consumes state-machine Ada
    class_test/         sample — consumes class-model Ada
    samples/            .puml sources (nested.puml, zoo.puml)
    bootstrap.sh        regenerate sample projects after a fresh clone

## Toolchain

- Alire 2.x, `alr` on PATH
- GNAT 12+ with `-gnat2022 -gnatX`
- macOS (BSD userland). Shell is zsh.

## Build and run

Core crates:

    cd plantuml_parser && alr build
    cd ../hsm_runtime  && alr build
    cd ../plantuml2code && alr build

Sample projects need generated Ada, which is gitignored. From the
repo root, one command does everything:

    ./bootstrap.sh

CLI examples:

    cd plantuml2code
    ./bin/plantuml2code dump ../samples/nested.puml
    ./bin/plantuml2code dump -f json ../samples/nested.puml
    ./bin/plantuml2code dump -f ada -o /tmp/gen ../samples/nested.puml

Notes:

- `alr run` uses `--args="..."`, not `-- ...`.
- For debugging, invoke `./bin/<exe>` directly.

## Parser model

`PlantUML.States.State_Diagram` and `PlantUML.Classes.Class_Diagram`
use the same pool-and-index design:

- `Pool : *_Vectors.Vector` — flat list of all entities
- `Roots : Index_Vectors.Vector` — indices of top-level entities
- Each entity carries `Children : Index_Vectors.Vector` with indices
  into the pool

This shape exists because Ada containers can't hold self-referential
records directly. It's the standard workaround: flat storage,
index-based links.

### Pseudostates

Canonical names are region-scoped. The top-level `[*]` is named
`[*]_start` / `[*]_end`. An inner `[*]` inside `Running` is named
`Running.[*]_start` / `Running.[*]_end`. History is `[H]` or
`<region>.[H]`.

The parser writes these names during a single pass. Consumers
disambiguate regions by looking at children, not by re-parsing
the name.

### Transitions

Flat list. Each `Transition` has `From`, `To`, `Trigger`, `Guard`,
`Effect`, `Label`, `Kind`. `From` and `To` are names, not indices —
name lookup is done by the consumer.

### Annotations

A state's `Annotations` vector holds records with `Kind`, `Action`,
`Trigger`, `Guard`. `Kind` values: `Entry_Action`, `Exit_Action`,
`Do_Activity`, `Internal_Transition`, `Note`, `Stereotype`, `Unknown`.

### Classes

`Classifier` carries `Id`, `Display`, `Kind`, `Members`,
`Annotations`, `Children`. `Member` has `Kind`, `Vis`, `Id`,
`Type_Name`, `Params`, and static/abstract flags. `Relation` has
`From`, `To`, `Kind`, `Mult_From`, `Mult_To`, `Label`, `Stereotype`.

## Runtime

`HSM.Machines` is a generic package parameterised by
`(State, Event, Initial)`. It provides:

- `Machine`, an abstract tagged type with `Current`
- `Current_State`, `Next_State` (abstract), `On_Enter`, `On_Exit`,
  `On_Internal` (overridable), `Name` (abstract)
- `Start` — fires `On_Enter` for the initial state. Call once after
  construction.
- `Step` — the UML transition algorithm
- `Reset` — fires `On_Exit`, sets to `Initial`, fires `On_Enter`

Dispatch works because `Step`/`Start`/`Reset` take `Machine'Class`.
The generated bodies override the primitives, and the runtime calls
them through class-wide views.

`On_Internal` returns `True` if the event was consumed as an internal
transition. `Step` calls it before computing the next state.

`Utilities.Tracing` is a global tracer hook. The sample driver installs
one that writes to stdout. Tracing only fires on actual state changes.

## Generator

Two independent code paths, both under `plantuml2code/src/`:

- `plantuml2code_ada.adb` — state diagrams
- `plantuml2code_ada_classes.adb` — class diagrams

Both emit four files per entity:

    <Package>.ads           spec, regenerated
    <Package>.adb           body, regenerated
    <Package>_Actions.ads   action stubs, emitted once, never overwritten
    <Package>_Actions.adb   bodies the user edits

### State machines

`Generate_Region` is recursive. For each `Composite` state, it spawns
a child region, producing `<Child>_Machine.ads`/`.adb`. The parent
holds each child by value:

    type Machine is new Base.Machine with record
       Running_Child : Running_Machine.Machine;
    end record;

The parent's `On_Enter` for a composite state calls
`Running_Machine.Base.Reset (Self.Running_Child)`. The parent exposes
a `Step_<Child>` procedure so the driver can dispatch child events.

Identifier sanitization: `Sanitize` keeps alphanumerics, replaces
others with `_`, collapses runs, prefixes `S_` if leading digit,
returns `Unnamed` if empty. `State_Literal` maps pseudostates to
`Start_State`, `End_State`, `History`, `Deep_History`.

### Classes

Each class becomes its own package. `T` is the tagged type.
Attributes become record fields with an `Attr_` prefix (this avoids
colliding with method names — Ada identifiers are case-insensitive
and selected components win over primitives).

- Inheritance: `type T is new Parent.T with null record;`
- Interfaces: `type T is interface;` with abstract methods
- Enums: `type T is (A, B, C);`
- Method stubs: `raise Program_Error` with an unreachable `return`
  (expression functions that only raise are elided by GNAT)
- Inherited abstract methods are auto-overridden so concrete
  derived types compile

### Identifier type mapping

`Map_Type` in the class generator maps PlantUML type names to Ada:
`String` → `Unbounded_String`, `Boolean` → `Boolean`, `Float`/`Double`
→ `Float`, `Int`/`Long` → `Integer`, everything else → `Integer`.

## Templates

Templates Parser syntax (NOT Mustache/ERB):

- Tags: `@_TAG_@`
- Filters: `@_FILTER:VAR_@`
- Directives: `@@TABLE@@ ... @@END_TABLE@@`, `@@IF@@ @_BOOL_TAG_@ ... @@END_IF@@`
- Length attribute: `@_VAR'Length_@`

Tag delimiters default to `@_` and `_@`.

### Directive placement rules

The parser is strict about where directives appear:

- `@@IF@@`, `@@ELSE@@`, and `@@END_IF@@` must start a line at
  column 1 with no leading whitespace.
- The boolean expression follows on the same line as `@@IF@@`:
  `@@IF@@ @_TAG_@`. The tag itself can end the line; the newline
  is consumed.
- `@@TABLE@@` and `@@END_TABLE@@` also start a line at column 1.
- Directives glued to preceding content on the same line are
  emitted as literal text, not interpreted.

### What the templates do

The four Ada templates carry the *shape* of the emitted code. The
generator supplies flat, aligned composite tags; the templates
iterate them with `@@TABLE@@` and branch with `@@IF@@`.

State diagram tags (from `plantuml2code_ada.adb`):

| Group | Tags |
|-------|------|
| Header | `PACKAGE_NAME`, `DESCRIPTION`, `SOURCE_DIAGRAM`, `GENERATION_DATE` |
| Types | `STATE_LITERALS`, `EVENT_LITERALS`, `INITIAL_STATE`, `CHILD_WITH_CLAUSES`, `PRIVATE_RECORD`, `STEP_CHILD_DECLS`, `STEP_CHILD_BODIES` |
| On_Enter | `ENTER_STATE_LIT`, `ENTER_IS_END`, `ENTER_IS_COMPOSITE`, `ENTER_IS_LEAF_WITH_ACTION`, `ENTER_IS_LEAF_NO_ACTION`, `ENTER_CHILD_PKG`, `ENTER_CHILD_FIELD`, `ENTER_ACTION_CALL` |
| On_Exit | `EXIT_STATE_LIT`, `EXIT_HAS_ACTION`, `EXIT_NO_ACTION`, `EXIT_ACTION_CALL` |
| On_Tick | `TICK_STATE_LIT`, `TICK_HAS_ACTION`, `TICK_ACTION_CALL` |
| On_Internal | `INTERNAL_STATE_LIT`, `INTERNAL_HAS_ANY`, `INTERNAL_HAS_EVENT`, `INTERNAL_EVENT_LIT`, `INTERNAL_ACTION_CALL` |
| Transition table | `TABLE_ROW_STATE`, `TABLE_ROW_EVENTS`, `TABLE_ROW_NOTLAST` |
| Actions files | `ACTION_DECLS`, `ACTION_BODIES` |

### Adding a new output format

A `.tmplt` file plus a binding function that populates the tags.
No changes to the generator's Ada formatting logic are needed.

### What still lives in Ada

- Recursive child-package generation (each composite region is its
  own template invocation).
- The composite-tree reconstruction (`Region_Of`, `States_In`,
  `Transitions_In`, `Composite_Children_Of`).
- Identifier sanitization (`Sanitize`, `State_Literal`,
  `Event_Literal`, `Effective_Target`).
- The event list and transition target lookup.

These are data preparation, not code shaping.

### Template location

`PlantUML2Code_Template_Path.Locate` searches, in order:

1. CLI override (`-t <dir>`)
2. `$PLANTUML2CODE_TEMPLATES`
3. `<parent-of-cwd>/resources/templates`
4. `<cwd>/resources/templates`

The generator assumes templates are under `resources/templates/<format>/`.
Running the CLI from a different directory than the crate root will
fail unless `-t` is passed. This is why `bootstrap.sh` `cd`s into
`plantuml2code` before generating.

## Known gotchas

### Ada / GNAT

- `Body`, `Exit`, `Delta`, `Range`, `Digits`, `Mod`, `Access`,
  `Interface`, `Package`, `Private`, `Protected` are reserved words.
- `Standard_Error'Access` doesn't work — `Standard_Error` is a function.
- A record field named `Name` shadows the `Name` subtype for later
  fields in the same record. Prefix fields or rename the subtype.
- `Ada.Directories.Compose` refuses multi-segment second arguments.
  Use string concatenation with `/`.
- `Library_Interface` in a library GPR must list every unit
  transitively withed by any listed unit's *spec*.
- Expression functions that only raise are elided by GNAT. Use an
  explicit `begin raise ...; return Dummy; end;` body.
- `-gnatX` enables `[]` aggregate syntax. `-gnatwa` warns about `()`.
- Subprograms must be declared before use. Nested subprograms need
  forward declarations if they call each other.

### macOS

- BSD `sed`: `sed -i ''` (no space) or use `perl -i.bak`.
- Files created via shell heredoc get a `com.apple.provenance` xattr.
  `xattr -c` doesn't always clear it. Copy via `cp` to a fresh path
  if a binary can't open them.
- `tail -5` doesn't accept the combined `-5` form on some BSD tools;
  use `tail -n 5`.

### Alire

- `alr publish` has no `--dry-run`; use `--skip-submit`.
- Test manifests are generated under `<crate>/alire/releases/` and
  should be tracked in git even though the rest of `alire/` is
  gitignored. The `.gitignore` exception requires `git add -f`.
- `alr run` uses `--args="..."`, not `-- ...`.

## Class-diagram output

Generating `ada` from a class diagram produces a self-contained
Alire project like the state side. Files emitted:

    <Output>/
      src/
        class_runtime.ads           root interface (Class_Runtime.Object)
        class_runtime-tracing.ads/.adb
        <Class>.ads/.adb            one package per classifier
        <Class>_Actions.ads/.adb    only when the class has methods
      tests/
        driver.adb                  constructs every concrete class
      setup.sh                      builds and runs

All classes derive from `Class_Runtime.Object`, a limited interface
with a single abstract `Class_Name` function. Interfaces use
`type T is limited interface and Class_Runtime.Object;`. Concrete
classes use `type T is new Class_Runtime.Object with ...`.

Enumerations get a concrete `T` with a `Class_Name` body but no
Actions file.

The generated `driver.adb` constructs each concrete class, calls
`Class_Name`, and prints it. Abstract classes and interfaces are
skipped (they cannot be constructed).

## Known limitations

- **History pseudostates** (`[H]`, `[H*]`) parse but are inert. They
  behave like ordinary states with self-loops.
- **Pseudostate transiency.** `Start_State` requires an explicit
  `Start (M)` call. UML says the initial pseudostate should
  auto-fire on entry to the region.
- **Multi-segment path components** not fully supported in the
  template path resolver.
- **Diamond inheritance** would produce `type T is new A.T and B.T`
  which Ada supports, but we haven't tested method resolution in
  that case.
- **Class associations** generate access-typed fields, but the
  driver never populates them. Allocation and ownership are the
  user's responsibility.
- **Class method bodies** raise `Program_Error` when unimplemented.
  The user edits `<Class>_Actions.adb` to provide real bodies.

## Pending corrections

These are known deviations from the intended design. They are
technical debt, not features. Each has a concrete remediation.

### 1. AUnit coverage (partial)

`plantuml_parser` and `plantuml2code` each ship an AUnit suite.
Run each with:

    cd plantuml_parser   && ./run_tests.sh
    cd ../plantuml2code  && ./run_tests.sh

Current coverage:

- `plantuml_parser`: Tokens (8 tests), States (9 tests),
  Classes (6 tests). Covers the tokenizer, diagram-kind detection,
  transition parsing (trigger, guard), composite children,
  entry annotations, region-scoped history, and class-model
  parsing (members, inheritance, interfaces, enumerations).
- `plantuml2code`: Ansi (2 tests), CLI (1 test), Formats
  (5 tests). Covers color-mode toggling and format-name parsing.

Test suites:

| Suite | Tests |
|-------|-------|
| Tokens | 8 |
| States | 9 |
| Classes | 6 |
| Ansi | 2 |
| CLI | 18 |
| Formats | 5 |
| Generator.Class | 5 |
| Generator.States | 10 |

The generator suites run the real generator against tiny
diagrams, writing to `/tmp/gen_test_*`, then assert on the
generated source text: state enums, initial state, transition
tables, entry/exit actions, internal transitions, composite
children and resets, terminal marking, interface kinds, and
subclass derivation.

Remaining gaps:

- Help text has no tests.
- The shipped runtime templates (`state_machine.*`,
  `class_runtime.*`) have no direct tests. They are exercised
  indirectly by the golden files and the three sample projects
  under `gen_test/`, `class_test/`, and `history_test/`.

### Argument-vector parsing

`PlantUML2Code_CLI.Parse` has two forms:

- `Parse (Args : Argument_Vectors.Vector)` — pure, used by tests.
- `Parse` — reads `Ada.Command_Line`, delegates to the above.

All CLI edge cases (attached vs. separated option values, missing
values, unknown options, multiple commands, help topics, color
modes, stdin) are covered by `Test_CLI`.

### 2. Minor known issues

- `PlantUML.Tokens` has an unused `with Ada.Characters.Handling`.
- `plantuml2code_template_path.adb` has a debug block guarded by
  `PLANTUML2CODE_DEBUG`; harmless but should be removed once the
  search logic is settled.
- `plantuml2code_ada.adb` has an unused `Child_Field` constant and
  `plantuml2code_ada_classes.adb` has unused `Has_Parents` and
  `Parents` functions. Cosmetic.

## Publishing



Both `plantuml_parser` and `hsm_runtime` are publishable to the Alire
community index. Their manifests are at:

    plantuml_parser/alire/releases/plantuml_parser-0.1.0.toml
    hsm_runtime/alire/releases/hsm_runtime-0.1.0.toml

To submit a new version:

    cd plantuml_parser && alr publish
    cd ../hsm_runtime && alr publish

Each opens a PR against `alire-project/alire-index`. Requires a
GitHub Personal Access Token with `repo` scope, configured for
`alr`. See https://github.com/alire-project/alire/blob/master/doc/publishing.md
