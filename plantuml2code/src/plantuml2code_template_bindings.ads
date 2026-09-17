with Templates_Parser;
with PlantUML.States;
with PlantUML.Classes;

package PlantUML2Code_Template_Bindings is

   function For_States
     (D : PlantUML.States.State_Diagram)
      return Templates_Parser.Translate_Set;

   function For_Classes
     (D : PlantUML.Classes.Class_Diagram)
      return Templates_Parser.Translate_Set;

   procedure Register_Filters;

end PlantUML2Code_Template_Bindings;
