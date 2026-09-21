with UML.Model;

package PlantUML2Code_Formats is

   type Format is (Text, Json, Ada_HSM);

   function Parse (S : String) return Format;

   procedure Set_Output_Dir (Dir : String);

   --  State diagrams: consume the normalized model.
   procedure Emit_States
     (Fmt  : Format;
      D    : UML.Model.Diagram;
      Path : String := "");

   procedure Emit_Classes
     (Fmt  : Format;
      D    : UML.Model.Diagram;
      Path : String := "");

end PlantUML2Code_Formats;
