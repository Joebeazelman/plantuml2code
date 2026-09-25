--  Ada class-diagram code generation.
--
--  Consumes the normalized UML.Model.Diagram; the parser is not
--  visible here.  This body is a language-agnostic orchestrator:
--  it walks the model, builds dictionaries with raw values, and
--  delegates all formatting to Jintp templates.

with UML.Model;
with Jintp;

package Uml2Code_Ada_Classes is

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String);

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String;
      Env            : in out Jintp.Environment);

   --  Raised when the diagram is structurally invalid for code
   --  generation. All errors are printed to Standard_Error before
   --  the exception is raised; nothing is written to Out_Dir.
   Validation_Error : exception;

end Uml2Code_Ada_Classes;
