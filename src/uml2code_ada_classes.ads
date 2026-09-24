--  Ada class-diagram code generation.
--
--  Consumes the normalized UML.Model.Diagram; the parser is not
--  visible here.

with UML.Model;

package Uml2Code_Ada_Classes is

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String);

   --  Raised when the diagram is structurally invalid for code
   --  generation. All errors are printed to Standard_Error before
   --  the exception is raised; nothing is written to Out_Dir.
   Validation_Error : exception;

end Uml2Code_Ada_Classes;
