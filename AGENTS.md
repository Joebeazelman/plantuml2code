# uml2code — agent notes

Parse PlantUML state and class diagrams into a normalized model, then
generate Ada 2022 code from that model. This document is the map;
read it before making changes.

## Layout

    plantuml_parser/    library — tokenizer, PlantUML parsers, UML.Model
    uml2code/      application — CLI and generators
    samples/            .puml sources (nested, zoo, history, adb_protocol)
    tests/              golden-file tests (repo root)
    README.md           user-facing overview
    PUBLISHING.md       Alire submission process

## Toolchain

- Alire 2.x, `alr` on PATH
- GNAT 16, `-gnat2022 -gnatX`
- macOS (BSD userland). Shell is zsh.

`gprbuild` and `gnatmake` are not on PATH — they live under
`~/.local/share/alire/toolchains/`. Invoke via `alr exec -- gprbuild`
or use the full path.

## Build and test

    cd plantuml_parser && alr build
    cd ../uml2code && alr build

    cd plantuml_parser && ./run_tests.sh    # AUnit, 24 tests
    cd ../uml2code && ./run_tests.sh   # AUnit, 46 tests
    cd .. && ./tests/run_tests.sh           # golden files

`tests/run_tests.sh` refuses to run if any source file is newer than
`uml2code/bin/uml2code`. If it complains, rebuild. This
prevents a failed build from silently passing goldens against a stale
binary.

## Architecture

### Normalized model

`UML.Model` is the single internal representation. Types only:

- `Diagram` — `Id`, `Kind`, `Metadata`, `Elements`, `Roots`,
  `Relations`, `Notes`
- `Element` — `Id`, `Display`, `Kind`, `Annotations`, `Notes`,
  `Members`, `Children`, `Parent`
- `Relation` — `From`/`To` (element indices), `Kind`, `Trigger`,
  `Guard`, `Effect`, `Label`, `Mult_From`, `Mult_To`, `Stereotypes`,
  `Notes`
- `Note` — `Text`, `Subject`, `Position`
- `Member` — `Kind`, `Id`, `Type_Name`, `Params`, `Vis`, flags

`UML.Model.Queries` provides structural helpers over the flat model:
`Find_By_Id`, `Require_By_Id`, `Region_Of`, `States_In`,
`Transitions_In`, `Is_Composite`, `Is_History`, `Parents_Of`,
`Associations_From`.

### Public parser entry point

`PlantUML.Parse (Source : String) return UML.Model.Diagram` is the
only parser API external code uses. `PlantUML.Detect_Kind` routes by
keyword: `state` for state diagrams; `class`, `abstract`, `interface`,
`enum`, `record`, `annotation`, `package`, `object` for class
diagrams.

`PlantUML.States` and `PlantUML.Classes` remain as internal parsers.
`PlantUML.To_Model` translates their types into `UML.Model`. The
parser types are not part of the library's public interface.

### Tokenizer

`PlantUML.Tokens`. `Token` has `Kind`, `Text`, `Line`, `Space_Before`.
`Space_Before` records whether whitespace preceded the token — needed
to reconstruct notes with original spacing. `Decode_Escapes` turns
`\n` sequences into real newlines; used by both parsers when
assembling note text.

### Notes

Two forms:

- **State diagrams:** `State : text` is a note, unless the line
  contains `/`, in which case it's an action annotation.
- **Class diagrams:** `note right|left|top|bottom of X : text`
  attaches to classifier `X`; `note "text"` is diagram-level.

Multi-line note text uses `\n` escapes, decoded at parse time.
Element-attached notes end up in `Element.Notes`; diagram-level notes
end up in `Diagram.Notes`.

### Package membership

For class diagrams, `Element.Parent` and `Element.Children` record
the PlantUML package hierarchy. `From_Classes` reverse-populates
`Parent` from `Children` after translation so consumers can walk
either direction. The class generator uses this to emit one Ada
package per PlantUML package.

## Generators

Both consume `UML.Model.Diagram` and are template-driven. Ada code
in the generators prepares data (tags, vectors); templates decide
the shape of the output.

### State generator (`uml2code_ada.adb`)

Recursive over composite regions. Each composite state spawns a
child region and a corresponding `<Child>_Machine` package. The
parent holds the child machine by value and exposes a
`Step_<Child>` procedure.

Emits per machine:

    <Package>.ads              spec
    <Package>.adb              body
    <Package>_Actions.ads      stub declarations
    <Package>_Actions.adb      stub bodies (emitted once)

Plus shared runtime (`state_machine.*`) and project scaffolding
(`setup.sh`, `tests/driver.adb`) once per output directory.

### Class generator (`uml2code_ada_classes.adb`)

One Ada package per PlantUML package. Top-level classifiers go in a
root package named after the diagram, or `Model` if unnamed.

Naming: identifier positions use `Ident = Ada_Case (Sanitize (...))`.
Ada casing: first letter of each underscore-separated word upper,
rest lower. So `host_protocol` → `Host_Protocol`.

Type declarations:

- Root class: `type X is [abstract] tagged record ... end record;`
  (or `tagged null record` when empty)
- Derived: `type X is [abstract] new Parent [and Iface]* with ...`
- Interface: `type X is limited interface;`
- Enum: `type X is (A, B, C);`

Method bodies delegate to `<Package>.Operations`, a child package:

    package body Animals is
       procedure Fetch (Self : in out Dog) is
       begin
          Operations.Fetch (Self);
       end Fetch;
    end Animals;

Operations stubs: procedures get `null`, functions get
`raise Program_Error` followed by an unreachable dummy return (GNAT
elides expression functions that only raise).

No runtime. No `Class_Runtime`. No `Class_Name`. Fields use
`access X'Class` for class-typed associations, direct value for enum
associations.

### Validation

`uml2code_ada_classes.Validate` runs before any output is
emitted. Errors print to stderr; the exception `Validation_Error`
is raised if any occurred, and no files are written. Checks:

- Classifier name is not an Ada reserved word
- Realization target is an interface
- Interface parents are interfaces
- At most one class parent per class
- No inheritance cycles
- Concrete classes implement all inherited abstract methods

### Identifier sanitization

`Sanitize` keeps alphanumerics, replaces others with `_`, collapses
runs, prefixes `T_` for leading digit, returns `Unnamed` if empty.
`Ada_Case` applies Ada identifier casing. `Ident` composes both.

`State_Literal` maps pseudostates: `[*]_start` → `Start_State`,
`[*]_end` → `End_State`, `[H]` → `History`, `[H*]` → `Deep_History`.

### Type mapping

`Map_Type` in the class generator maps PlantUML type names to Ada:
`String` → `Unbounded_String`, `Boolean` → `Boolean`,
`Float`/`Double`/`Real` → `Float`, `Int`/`Long`/`Short` →
`Integer`, empty → `""` (procedure, not function).

## Templates

Templates_Parser syntax, not Mustache or ERB.

- Tags: `@_TAG_@`
- Filters: `@_FILTER:VAR_@`
- Directives: `@@TABLE@@ ... @@END_TABLE@@`,
  `@@IF@@ @_BOOL_TAG_@ ... @@END_IF@@`

### Directive placement

Strict:

- `@@IF@@`, `@@ELSE@@`, `@@END_IF@@`, `@@TABLE@@`, `@@END_TABLE@@`
  must start at column 1 with no leading whitespace.
- The boolean expression follows on the same line as `@@IF@@`:
  `@@IF@@ @_TAG_@`.
- A `@@TABLE@@` block iterates **all tags of equal length** in the
  Translate_Set in lockstep. There is no per-table argument.
- Nested tables work if every directive is on its own line.
- Directives glued to preceding content on the same line are emitted
  literally.

### Layout

    resources/templates/
      ada/
        state/     state.ads.tmplt, state.adb.tmplt, actions.*
        class/     class.ads.tmplt, class.adb.tmplt,
                   class_operations.ads.tmplt, class_operations.adb.tmplt
        runtime/   state_machine.*.tmplt (shared across kinds)
        project/   driver.adb.tmplt, setup.sh.tmplt
      json/
        state/, class/
      default/
        state/, class/

Format subdir selects the template set; kind subdir selects within it.
`runtime/` and `project/` live at the format level because they're
shared by both kinds.

### Tag conventions

Header tags, both generators:

| Tag | Meaning |
|-----|---------|
| `PACKAGE_NAME` | Ada package name |
| `HAS_TITLE`, `TITLE_LINE` | Title metadata, root only |
| `HAS_NOTES`, `NOTES_HEADER` | Diagram notes, root only |
| `WITH_CLAUSES` | Pre-rendered `with`/`use` block |

State generator tags: `STATE_LITERALS`, `EVENT_LITERALS`,
`INITIAL_STATE`, `CHILD_WITH_CLAUSES`, `PRIVATE_RECORD`,
`STEP_CHILD_DECLS`, `STEP_CHILD_BODIES`, and one family per generated
subprogram section (`ENTER_*`, `EXIT_*`, `TICK_*`, `INTERNAL_*`,
`TABLE_ROW_*`). `ENTER_NOTE` carries per-state inline note comments.

Class generator tags: `DECL_BLOCK` (one multi-line type declaration
per row), `METHOD_BODY` (per-row method body blocks), `OP_DECL`,
`OP_BODY` (per-row Operations declarations/bodies).

### Adding a new output format

Drop a directory under `resources/templates/<format>/` with `state/`
and `class/` subdirectories. Add a binding function in
`uml2code_template_bindings.adb` that populates the tags. No
changes to the Ada formatting logic are needed if the format is
generated via templates.

### Template location

Resolution order:

1. `-t <dir>` CLI flag
2. `./uml2code.conf` — flat `key = value`, key `templates_dir`
3. `~/.config/uml2code/config`
4. `$UML2CODE_TEMPLATES`
5. `resources/templates` relative to cwd, exe dir, or parent

`Load_Config` reads project then home; a malformed config raises
`Config_Error`. `-t` short-circuits config reading.

## CLI

    uml2code dump <file>                   text
    uml2code dump -f json <file>           JSON
    uml2code dump -f ada -o <dir> <file>   generate Ada
    uml2code kind <file>                   detect diagram kind
    uml2code help [topic]
    uml2code --version

`-f text` routes to `Uml2Code_Model_Dump`, not the templates —
it's a developer diagnostic, not a generated format. `-f json` routes
through the `json/` templates via `For_States`/`For_Classes`.

## Testing

### AUnit

`plantuml_parser/tests/` — 24 tests: Test_Tokens, Test_States,
Test_Classes (including `Detect_Kind` for enum-only diagrams).

`uml2code/tests/` — 46 tests: Test_Ansi, Test_CLI (18),
Test_Config (6), Test_Formats (5), Test_Generator_Class (5),
Test_Generator_States (10).

Both test projects use `alr exec -- gprbuild -P <name>_tests.gpr`.

### Golden files

`tests/golden/{nested,zoo,history,adb}/` compare every emitted `.ads`,
`.adb`, and `driver.adb` against the generator's current output.
Normalization is `tests/normalize.sed` (dates, absolute paths).

    ./tests/run_tests.sh        # verify (fails if binary is stale)
    ./tests/update_golden.sh    # accept current output

Any change that alters output must either match existing goldens or
update them intentionally in the same commit.

### Generated project as build test

`dump -f ada -o <dir>` writes a self-contained Alire project:

    <dir>/
      src/       generated .ads/.adb (+ runtime, if state diagram)
      tests/     driver.adb — constructs each concrete class
      setup.sh   writes alire.toml + GPR, builds, runs

`bash <dir>/setup.sh` verifies the generated code compiles and runs.
This is the strongest single check on the generators.

## Roadmap

### 1. Normalized UML model — done

`UML.Model`, `UML.Model.Queries`, `PlantUML.Parse`. Both generators
consume the model. Parser types are internal.

### 2. Template set by `<format>/<diagram-kind>` — done

### 3. User-chosen template location — done

`uml2code.conf` and `~/.config/uml2code/config`.

### 4. Notes and comments in generated code — done

Diagram notes in the root `.ads` header. Element-attached notes
inline above the classifier (class) or case arm (state).

### 5. AUnit test project in generated output

Every generated project should include a generated AUnit test suite
covering the emitted API. For state machines: instantiate, drive
through representative steps, assert on transitions. For classes:
instantiate each concrete class, exercise `_Operations` stubs.

Needs: a test-suite GPR template, an `alire.toml` template that
depends on `aunit`, and generated test-case templates per diagram
kind.

### 6. Rename to uml2code

Rename crate names, project names, executable names, GPR projects,
`with` clauses, install prefix, environment variable names,
documentation, and directory names. Deferred until the items above
are done.

### Deferred / open

- **State-side naming.** `Running_Machine` and `Nested_Actions`
  siblings could become child packages (`Running.Machine`,
  `Nested.Actions`) matching the class-side `X.Operations` convention.
- **`-f text` unification.** Decide whether `Text` routes through
  the `default/` templates (making them live), or `default/` is
  dropped and `Model_Dump` stays canonical.
- **Multiplicity.** Parsed into `Relation.Mult_From`/`Mult_To` but
  ignored by the class generator. `1..*` should become a container
  field.
- **ansiada.** Replace hand-rolled SGR wrappers in
  `Uml2Code_Ansi` with the `ansiada` crate. Also fix `Auto`
  color mode to use `isatty (stdout)` instead of the `NO_COLOR` +
  `TERM` heuristic.

## Known gotchas

### Ada / GNAT

- Reserved words to avoid as identifiers: `Body`, `Exit`, `Delta`,
  `Range`, `Digits`, `Mod`, `Access`, `At`, `Interface`, `Package`,
  `Private`, `Protected`.
- A record field named `Name` shadows the `Name` subtype. Rename the
  field to `Id`.
- `use UML.Model` brings `Element` (the type) and `Tag` (an
  `Annotation_Kind` literal) into scope, colliding with
  `Ada.Strings.Unbounded.Element` and `Templates_Parser.Tag`. Add
  local `subtype` aliases at package-body scope:
  `subtype Element is UML.Model.Element;` and
  `subtype Tag is Templates_Parser.Tag;`.
- Enum comparison with `=` requires `use type <Pkg>.<Enum_Type>;`
  at the site of the comparison.
- Expression functions that only raise are elided by GNAT. Use an
  explicit `begin raise ...; return Dummy; end;` body.
- `Ada.Directories.Compose` refuses multi-segment second arguments.
  Use string concatenation with `/`.
- `Library_Interface` in a library GPR must list every unit
  transitively withed by any listed unit's spec. Adding a new public
  package to `plantuml_parser` requires updating
  `plantuml_parser.gpr`.
- Child packages see their parent's declarations without an explicit
  `with`, but the parent package **name** requires a `with` for `use`
  clauses. `with Parent;  use Parent;` triggers an "unnecessary with
  of ancestor" warning that is harmless.

### Alire

- `alr run` uses `--args="..."`, not `-- ...`.
- `alr publish` has no `--dry-run`; use `--skip-submit`.
- Test manifests under `<crate>/alire/releases/` are tracked even
  though the rest of `alire/` is gitignored.

### macOS

- BSD `sed`: `sed -i ''` (no space) or use `perl -i.bak`.
- Files created via shell heredoc get a `com.apple.provenance` xattr.

### Tooling

- Python heredocs inside `fix.sh` (the scratch runner) have trouble
  with Ada source that contains triple quotes. Prefer writing the Ada
  to a file with `cat > /tmp/x.ada <<'EOF'` and then splicing by line
  range from a Python script that does not embed Ada text.
- Prefer line-range replacement over string-anchor replacement when
  editing generated Ada — anchors are fragile against whitespace.

## Known limitations

- **History pseudostates** (`[H]`, `[H*]`) parse but are inert.
- **Pseudostate transiency.** `Start_State` requires an explicit
  `Start (M)` call.
- **Multi-segment template paths** — the resolver handles them, but
  the fallback to `default/` is only tried at the top level.
- **Diamond inheritance** — Ada allows multiple interface derivation,
  but method resolution with two concrete class parents is rejected
  by validation (correctly, since Ada forbids it).
- **Class associations** generate access-typed fields; the driver
  never populates them. Ownership is the user's responsibility.
- **Class method bodies** raise `Program_Error` until the user fills
  in `<Package>.Operations`.
- **Multiplicity** is parsed but not honoured.
