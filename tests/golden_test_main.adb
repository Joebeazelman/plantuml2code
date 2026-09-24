with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Command_Line;
with Golden_Runner;

procedure Golden_Test_Main is
   Results : constant Golden_Runner.Result_Vectors.Vector :=
     Golden_Runner.Run_All_Golden_Tests;
   Pass_Count  : Natural := 0;
   Fail_Count  : Natural := 0;
   Error_Count : Natural := 0;
begin
   Put_Line ("=== Golden Test Results ===");
   Put_Line ("");

   for R of Results loop
      declare
         Name : constant String := To_String (R.Scenario_Name);
         Msg  : constant String := To_String (R.Message);
      begin
         case R.Result is
            when Golden_Runner.Pass =>
               Put_Line ("PASS: " & Name);
               Put_Line ("      " & Msg);
               Pass_Count := Pass_Count + 1;
            when Golden_Runner.Fail =>
               Put_Line ("FAIL: " & Name);
               Put_Line ("      " & Msg);
               Fail_Count := Fail_Count + 1;
            when Golden_Runner.Error =>
               Put_Line ("ERROR: " & Name);
               Put_Line ("       " & Msg);
               Error_Count := Error_Count + 1;
         end case;
      end;
   end loop;

   Put_Line ("");
   Put_Line ("=== Summary ===");
   Put_Line ("Total Tests: " & Natural'Image (Natural (Results.Length)));
   Put_Line ("Passed:      " & Natural'Image (Pass_Count));
   Put_Line ("Failed:      " & Natural'Image (Fail_Count));
   Put_Line ("Errors:      " & Natural'Image (Error_Count));

   if Fail_Count > 0 or else Error_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
end Golden_Test_Main;
