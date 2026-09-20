--  Translate PlantUML parse results into UML.Model.Diagram values.
--
--  The PlantUML parser's own types (State_Diagram, Class_Diagram)
--  stay internal. Consumers use this package, or PlantUML.Parse,
--  to obtain a UML.Model.Diagram.

with UML.Model;
with PlantUML.States;
with PlantUML.Classes;

package PlantUML.To_Model is

   function From_State (D : PlantUML.States.State_Diagram)
                        return UML.Model.Diagram;

   function From_Classes (D : PlantUML.Classes.Class_Diagram)
                          return UML.Model.Diagram;

end PlantUML.To_Model;
