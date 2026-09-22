with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Nested_Tests;
with Running_Machine_Tests;

function Nested_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new Nested_Tests.Case_Type);
   Add_Test (Result, new Running_Machine_Tests.Case_Type);
   return Result;
end Nested_Suite;
