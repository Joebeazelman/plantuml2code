with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Test_Ansi;
with Test_CLI;
with Test_Formats;
with Test_Generator_Class;
with Test_Generator_States;

function All_Tests return Access_Test_Suite is
   Result : constant Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
begin
   Result.Add_Test (new Test_Ansi.Case_Type);
   Result.Add_Test (new Test_CLI.Case_Type);
   Result.Add_Test (new Test_Formats.Case_Type);
   Result.Add_Test (new Test_Generator_Class.Case_Type);
   Result.Add_Test (new Test_Generator_States.Case_Type);
   return Result;
end All_Tests;
