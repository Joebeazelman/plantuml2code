with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Nested_Tests;

function All_Tests return Access_Test_Suite is
   Result : constant Access_Test_Suite := new AUnit.Test_Suites.Test_Suite;
begin
   Result.Add_Test (new Nested_Tests.Case_Type);
   return Result;
end All_Tests;
