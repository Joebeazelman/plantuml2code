with AUnit.Reporter.Text;
with AUnit.Run;
with AUnit;
with Ada.Command_Line;
with All_Tests;

procedure Test_Main is
   use type AUnit.Status;

   function Run is new AUnit.Run.Test_Runner_With_Status (All_Tests);

   Reporter : AUnit.Reporter.Text.Text_Reporter;
   Status   : constant AUnit.Status := Run (Reporter);
begin
   Ada.Command_Line.Set_Exit_Status
     (if Status = AUnit.Success
      then Ada.Command_Line.Success
      else Ada.Command_Line.Failure);
end Test_Main;
