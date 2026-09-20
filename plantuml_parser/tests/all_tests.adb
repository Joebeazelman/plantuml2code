with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Test_Tokens;
with Test_States;
with Test_Classes;

function All_Tests return Access_Test_Suite is
   Result : constant Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
begin
   Result.Add_Test (new Test_Tokens.Case_Type);
   Result.Add_Test (new Test_States.Case_Type);
   Result.Add_Test (new Test_Classes.Case_Type);
   return Result;
end All_Tests;
