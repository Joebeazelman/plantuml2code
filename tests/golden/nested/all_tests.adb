with Nested_Suite;

function All_Tests return AUnit.Test_Suites.Access_Test_Suite is
begin
   return Nested_Suite;
end All_Tests;
