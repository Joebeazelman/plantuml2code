--  Small helpers shared between the format renderers and the
--  code generators.

with Templates_Parser;

package Uml2Code_Utils is

   --  Locate and render a template.
   --
   --  Subdir is the template subdirectory: "default", "json", "ada".
   --  Template is the filename inside it, e.g. "state.tmplt".
   --
   --  Raises Uml2Code_Template_Path.Template_Not_Found if the
   --  template cannot be located.
   function Render_Template
     (Subdir   : String;
      Template : String;
      T        : Templates_Parser.Translate_Set) return String;

   --  Escape a string for inclusion inside a JSON string literal.
   --  Handles double quote, backslash, LF, CR, and HT. Other control
   --  characters pass through unchanged.
   function Escape_Json (S : String) return String;

   --  Return the basename of Path without its extension:
   --     "foo/bar.puml"  -> "bar"
   --     "bar"           -> "bar"
   --     ".profile"      -> ".profile"
   --     ""              -> ""
   function Basename_Without_Extension (Path : String) return String;

end Uml2Code_Utils;
