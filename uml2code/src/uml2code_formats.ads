with UML.Model;

package Uml2Code_Formats is

   type Format is (Text, Json, Ada_HSM);

   function Parse (S : String) return Format;

   procedure Set_Output_Dir (Dir : String);

   --  Template-driven output. Fmt is Json or Ada_HSM; Text is
   --  handled by Uml2Code_Model_Dump and never reaches these.
   procedure Emit_States
     (Fmt  : Format;
      D    : UML.Model.Diagram;
      Path : String := "");

   procedure Emit_Classes
     (Fmt  : Format;
      D    : UML.Model.Diagram;
      Path : String := "");

end Uml2Code_Formats;
