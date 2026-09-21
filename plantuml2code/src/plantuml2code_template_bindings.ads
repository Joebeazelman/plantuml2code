--  Parser-agnostic tag bindings for template rendering.
--
--  Produces a Translate_Set from a UML.Model.Diagram for both text
--  and JSON output. The parser is not visible here.

with Templates_Parser;
with UML.Model;

package PlantUML2Code_Template_Bindings is

   function For_States
     (D : UML.Model.Diagram)
      return Templates_Parser.Translate_Set;

   function For_Classes
     (D : UML.Model.Diagram)
      return Templates_Parser.Translate_Set;

   procedure Register_Filters;

end PlantUML2Code_Template_Bindings;
