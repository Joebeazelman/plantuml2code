# AI Agent Instructions

## For uml2code and plantuml_parser

### Includes full code review, architectural guidance, and refactored template system

---

## 1. Purpose of this document

This document provides a complete set of instructions for any AI agent responsible for:

- Maintaining or improving the uml2code generator
- Extending the system to new languages
- Refactoring templates
- Implementing adapter fragments
- Preserving language neutrality in the generator
- Ensuring runtime extensibility without recompilation

It is designed for automated consumption. Sections are clearly labeled and structured.

---

## 2. Core Principles

### 2.1 Language neutrality

The generator must remain language‑neutral. It should only understand UML semantics, not language syntax.

Examples of semantic concepts:

- Class is abstract
- Class has parents
- Class implements interfaces
- Class has fields
- Class has methods
- Multiplicity implies collection
- Visibility
- Stereotypes
- Notes
- Diagram metadata

These concepts exist in every language. They belong in the generator.

### 2.2 Language specificity

Language syntax must be isolated in adapter fragments.

Examples of Ada syntax:

- tagged
- abstract
- new Parent
- and Interface
- null record
- record
- function vs procedure
- access types
- Ada.Containers.Vectors
- with and use clauses

These belong in the adapter, not the generator.

### 2.3 Runtime extensibility

New languages must be added without recompilation.

This requires:

- Adapter fragments loaded at runtime
- Template directories loaded at runtime
- No language logic in compiled code
- No branching in main templates

---

## 3. Architecture

### 3.1 Pipeline

```text
UML → plantuml_parser → generator → language adapter → templates → output
```

**Generator**

Produces semantic view model.

**Language adapter**

Transforms semantics into language‑specific syntax.
Implemented as templates or config files.
Loaded at runtime.

**Templates**

Render final code.
Must be declarative.
No semantic logic.

---

## 4. Code Review Summary

### 4.1 Issues found in the original template

- Semantic logic mixed with Ada syntax
- Branching inside templates
- Naming rules scattered
- Inheritance rules embedded in template
- Method signature logic embedded in template
- Import rules embedded in template
- Vector instantiation logic embedded in template

These issues make templates brittle and make future languages harder to add.

---

## 5. Refactored Template System

### 5.1 Goals

- Remove branching from main templates
- Move all Ada syntax into adapter fragments
- Keep generator language‑neutral
- Allow new languages to be added by dropping in new adapter directories
- No recompilation required

---

## 6. Language‑Neutral View Model

The generator produces:

```text
package:
  name
  title_line
  notes_header
  imports
  enums
  interfaces
  classes
  vectors

class:
  name
  is_abstract
  parents
  interfaces
  fields
  methods
```

No language syntax.

---

## 7. Ada Adapter Output Model

The adapter produces:

```text
package.ada:
  imports_lines
  enums_blocks
  interfaces_blocks
  classes_blocks
  vectors_blocks

class.ada:
  type_header_line
  record_block
  methods_signatures
```

All Ada syntax lives here.

---

## 8. New Main Ada Template

This template is declarative. No branching.

```jinja
---------------------------------------------------------------------
-- {{ package.name | ada_ident }}
{{ package.title_line }}
{{ package.notes_header }}
---------------------------------------------------------------------

{% for line in package.ada.imports_lines %}
{{ line }}
{% endfor %}

package {{ package.name | ada_ident }} is

{% for enum_block in package.ada.enums_blocks %}
{{ enum_block }}
{% endfor %}

{% for iface_block in package.ada.interfaces_blocks %}
{{ iface_block }}
{% endfor %}

{% for klass in package.classes %}
{{ klass.ada.type_header_line }}
{{ klass.ada.record_block }}

{% for sig in klass.ada.methods_signatures %}
{{ sig }}
{% endfor %}

{% endfor %}

{% for vec_block in package.ada.vectors_blocks %}
{{ vec_block }}
{% endfor %}

end {{ package.name | ada_ident }};
```

---

## 9. Ada Adapter Fragments

### 9.1 Imports

```jinja
{% set lines = [] %}

{% if package.name != "Model" %}
{% set _ = lines.append("with Zoo; use Zoo;") %}
{% endif %}

{% if package.needs_unbounded %}
{% set _ = lines.append("with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;") %}
{% endif %}

{% if package.has_vector_instantiations %}
{% set _ = lines.append("with Ada.Containers.Vectors;") %}
{% endif %}

{{ lines }}
```

> **Note:** The `with Zoo; use Zoo;` line was a hack and must be removed. See Section 12.

### 9.2 Enum

```jinja
type {{ enum.name | ada_ident }} is (
{%- for lit in enum.literals -%}
{{ lit | ada_ident }}{% if not loop.last %}, {% endif %}
{%- endfor -%}
);
```

### 9.3 Interface

```jinja
type {{ iface.name | ada_ident }} is limited interface;
```

### 9.4 Class type header

```jinja
{% set parts = [] %}

{% if klass.is_abstract %}
{% set _ = parts.append("abstract") %}
{% endif %}

{% if klass.parents|length > 0 %}
{% set _ = parts.append("new " ~ klass.parents[0] | ada_ident) %}
{% endif %}

{% if klass.interfaces|length > 0 %}
{% if klass.parents|length > 0 %}
{% set _ = parts.append("and " ~ klass.interfaces[0] | ada_ident) %}
{% else %}
{% set _ = parts.append("new " ~ klass.interfaces[0] | ada_ident) %}
{% endif %}
{% endif %}

{% if klass.parents|length == 0 and klass.interfaces|length == 0 %}
{% set _ = parts.append("tagged") %}
{% endif %}

{% if klass.parents|length > 0 or klass.interfaces|length > 0 %}
{% set _ = parts.append("with") %}
{% endif %}

type {{ klass.name | ada_ident }} is {{ parts | join(" ") }}
```

### 9.5 Class record

```jinja
{% if klass.fields|length > 0 %}
record
{% for field_line in klass.field_lines %}
{{ field_line }}
{% endfor %}
end record;
{% else %}
null record;
{% endif %}
```

### 9.6 Method signatures

```jinja
{% if method.has_return_type %}
function {{ method.name | ada_ident }}
(Self : in out {{ klass.name | ada_ident }})
return {{ method.return_type | ada_type }};
{% else %}
procedure {{ method.name | ada_ident }}
(Self : in out {{ klass.name | ada_ident }});
{% endif %}
```

### 9.7 Vector instantiation

```jinja
type {{ vec.element_type | ada_ident }}_Access is access all {{ vec.element_type | ada_ident }}'Class;

package {{ vec.vector_name | ada_ident }} is new Ada.Containers.Vectors
(Index_Type => Positive,
Element_Type => {{ vec.element_type | ada_ident }}_Access);
```

---

## 10. Agent Action Items

### 10.1 Immediate tasks

- Implement adapter fragment loader
- Refactor existing Ada templates into fragments
- Update generator to produce semantic view model
- Update main Ada template to use adapter output

### 10.2 Medium tasks

- Add adapter validation
- Add adapter discovery
- Add adapter‑specific golden tests

### 10.3 Long term tasks

- Add new languages by creating new adapter directories
- Document adapter format for end users
- Maintain strict separation of semantics and syntax

---

## 11. Guided Links for Agent Navigation

- `language_adapter_design`
- `refactor_inheritance_logic`
- `method_signature_rules`
- `compute_imports`
- `template_decomposition`

---

If you want, I can now produce:

- A full example of the generator populating `package.ada.*`
- A complete Ada adapter directory structure
- A C sharp adapter example
- A Rust adapter example

Just tell me which direction you want to explore next.

---

> **You said:**
>
> The "with Zoo; use Zoo;" is dishonest attempt by the previous agent to get the template to pass a unit test. It's an error. Btw, is lines the same as comments? We should use the term comments and comment_line. I don't see any of them mentioned. I would like to support them as well. Do you think the language adapter should set word-wrap length from a configuration for multiline comments?

> **Copilot said:**
>
> Here is the clean, agent‑friendly update to your architecture and template strategy, incorporating your new points:
>
> - The `with Zoo; use Zoo;` line was a hack. It should be removed entirely.
> - Comments and comment lines should be first‑class citizens in the model.
> - Yes, the language adapter is the correct place to define word‑wrap rules for multiline comments.
> - No, “lines” is not the same as comments. We should use `comments` and `comment_lines` explicitly.
>
> Below is the updated section of your AI‑agent instructions document, rewritten to include comment support, removal of the Zoo hack, and a clean strategy for word‑wrapping.

---

## 12. Comment Support and Cleanup of Incorrect Imports

### 12.1 Removal of incorrect imports

The previous template contained:

```ada
with Zoo; use Zoo;
```

This was a workaround to satisfy a unit test. It is incorrect and must be removed from all templates and adapters.

**Agent directive**

Remove all references to Zoo.
Do not reintroduce them.
Do not generate imports based on hacks or test artifacts.

### 12.2 Comments vs lines

The system must distinguish:

- `comments`: semantic comment objects from UML (notes, annotations, documentation)
- `comment_lines`: rendered, language‑specific lines of text produced by the adapter

The generator produces semantic comments.
The adapter produces formatted comment lines.
The template simply inserts them.

**Agent directive**

Use the terms `comments` and `comment_lines`.
Never use “lines” as a synonym for comments.

### 12.3 Comment handling in the view model

Add to the language‑neutral model:

```text
package.comments
class.comments
method.comments
field.comments
```

Each comment is a semantic object:

```text
comment:
  text
  kind      # doc, note, annotation
  multiline # boolean
```

### 12.4 Comment handling in the Ada adapter

The Ada adapter must convert semantic comments into Ada syntax:

```ada
-- single line
-- multiple lines
-- wrapped lines
```

Example adapter output:

```text
class.ada.comment_lines = [
  "-- Customer represents a domain entity",
  "-- It is persisted in the database"
]
```

### 12.5 Word‑wrap configuration

Yes, the language adapter should control word‑wrap length.

**Why**

- Different languages have different comment conventions
- Different users prefer different wrap widths
- Templates should not contain wrapping logic
- Wrapping is formatting, not semantics

**Agent directive**

Add a configuration key:

```yaml
ada:
  comment_wrap: 78
```

The adapter must:

- Wrap multiline comments at the configured width
- Preserve indentation
- Preserve comment prefix (`--`)
- Avoid breaking Ada identifiers
- Avoid breaking URLs

### 12.6 Ada comment adapter fragment

```jinja
{# templates/ada/adapter/comment.tmplt #}

{% set wrap = config.ada.comment_wrap %}
{% set lines = [] %}

{% for comment in comments %}
{% if comment.multiline %}
{% for chunk in comment.text | wrap_text(wrap) %}
{% set _ = lines.append("-- " ~ chunk) %}
{% endfor %}
{% else %}
{% set _ = lines.append("-- " ~ comment.text) %}
{% endif %}
{% endfor %}

{{ lines }}
```

**Agent directive**

Implement `wrap_text` in the adapter layer, not in templates.

### 12.7 Inserting comments into the main Ada template

The main template stays declarative:

```jinja
{% for line in klass.ada.comment_lines %}
{{ line }}
{% endfor %}
```

No branching.
No wrapping.
No syntax logic.

---

## 13. Updated Ada Imports Adapter (Zoo removed)

```jinja
{# templates/ada/adapter/imports.tmplt #}
{% set lines = [] %}

{% if package.needs_unbounded %}
{% set _ = lines.append("with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;") %}
{% endif %}

{% if package.has_vector_instantiations %}
{% set _ = lines.append("with Ada.Containers.Vectors;") %}
{% endif %}

{{ lines }}
```

**Agent directive**

Imports must be driven by semantic needs only.
Never add imports to satisfy tests.

---

## 14. Updated Agent Action Items

### Immediate

- Remove Zoo import logic
- Add comment support to semantic model
- Add comment adapter fragments
- Add comment insertion points in templates
- Add word‑wrap configuration
- Implement `wrap_text` in adapter layer

### Medium

- Add comment‑specific golden tests
- Add adapter validation for comment formatting
- Add adapter discovery for comment fragments

### Long term

- Support language‑specific comment styles (C sharp, Rust, Python)
- Support docstring generation
- Support annotation rendering