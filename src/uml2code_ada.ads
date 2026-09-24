--  Ada HSM code generation from a state diagram.
--
--  Consumes the normalized UML.Model.Diagram; the parser is not
--  visible here.

with UML.Model;

package Uml2Code_Ada is

   --  Emit <Package_Name>.ads and <Package_Name>.adb into Out_Dir.
   procedure Generate
     (D              : UML.Model.Diagram;
      Package_Name   : String;
      Source_Diagram : String;
      Out_Dir        : String);

   procedure Emit_Runtime_And_Project
     (Src_Dir, Tests_Dir, Out_Dir : String;
      Machine_Name : String;
      Include_State_Runtime : Boolean := True);

   procedure Emit_Setup_Only (Out_Dir, Machine_Name : String);
   --  Emit the shared state-machine runtime and a starter project.
   --  Class diagrams set Include_State_Runtime to False; they still
   --  get a project skeleton and a driver, but no state-machine files.

end Uml2Code_Ada;
