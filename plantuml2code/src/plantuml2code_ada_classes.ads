--  Ada class-diagram code generation.
--
--  Consumes the normalized UML.Model.Diagram; the parser is not
--  visible here.

with UML.Model;

package PlantUML2Code_Ada_Classes is

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String);

end PlantUML2Code_Ada_Classes;
