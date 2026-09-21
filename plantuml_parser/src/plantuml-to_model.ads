--  Translate PlantUML parse results into UML.Model.Diagram values.

with UML.Model;
with PlantUML.States;
with PlantUML.Classes;

package PlantUML.To_Model is
   pragma Preelaborate;

   function From_State (D : PlantUML.States.State_Diagram)
                        return UML.Model.Diagram;

   function From_Classes (D : PlantUML.Classes.Class_Diagram)
                          return UML.Model.Diagram;

end PlantUML.To_Model;
