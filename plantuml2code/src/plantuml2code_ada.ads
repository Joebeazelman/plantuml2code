--  Ada HSM code generation from a state diagram.

with PlantUML.States;

package PlantUML2Code_Ada is

   --  Emit <Package_Name>.ads and <Package_Name>.adb into Out_Dir.
   procedure Generate
     (D              : PlantUML.States.State_Diagram;
      Package_Name   : String;
      Source_Diagram : String;
      Out_Dir        : String);

end PlantUML2Code_Ada;
