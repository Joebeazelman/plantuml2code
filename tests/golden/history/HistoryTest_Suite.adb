with AUnit.Test_Suites;  use AUnit.Test_Suites;
with HistoryTest_Tests;
with Outer_Machine_Tests;
with Middle_Machine_Tests;
with Inner_Machine_Tests;

function HistoryTest_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new HistoryTest_Tests.Case_Type);
   Add_Test (Result, new Outer_Machine_Tests.Case_Type);
   Add_Test (Result, new Middle_Machine_Tests.Case_Type);
   Add_Test (Result, new Inner_Machine_Tests.Case_Type);
   return Result;
end HistoryTest_Suite;
