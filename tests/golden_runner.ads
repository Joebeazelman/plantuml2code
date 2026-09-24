--  Golden test runner for uml2code
--  Compares generated output against expected golden files

with Ada.Strings.Unbounded;     use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Golden_Runner is

   type Test_Result is (Pass, Fail, Error);

   type Golden_Test_Result is record
      Scenario_Name : Unbounded_String;
      Result        : Test_Result := Pass;
      Message       : Unbounded_String;
   end record;

   package Result_Vectors is new Ada.Containers.Vectors (Positive, Golden_Test_Result);

   --  Run all golden tests and return results
   function Run_All_Golden_Tests return Result_Vectors.Vector;

   --  Run a single golden test scenario
   function Run_Golden_Test (Scenario_Name : String) return Golden_Test_Result;

end Golden_Runner;
