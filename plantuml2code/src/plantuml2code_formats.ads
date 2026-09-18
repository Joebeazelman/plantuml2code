with PlantUML.States;
with PlantUML.Classes;

package PlantUML2Code_Formats is

   type Format is (Text, Json, Ada_HSM);

   function Parse (S : String) return Format;

   procedure Set_Output_Dir (Dir : String);

   procedure Emit_States
     (Fmt  : Format;
      D    : PlantUML.States.State_Diagram;
      Path : String := "");

   procedure Emit_Classes
     (Fmt  : Format;
      D    : PlantUML.Classes.Class_Diagram;
      Path : String := "");

end PlantUML2Code_Formats;
