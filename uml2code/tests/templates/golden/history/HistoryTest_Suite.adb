with AUnit.Test_Cases;
with AUnit.Test_Suites;  use AUnit.Test_Suites;
with HistoryTest_Tests;
with Inner_Machine_Tests;

function HistoryTest_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
   type Ref_1 is
     access AUnit.Test_Cases.Test_Case'Class;
   T_1 : constant Ref_1 :=
     new HistoryTest_Tests.Case_Type;
   type Ref_2 is
     access AUnit.Test_Cases.Test_Case'Class;
   T_2 : constant Ref_2 :=
     new Inner_Machine_Tests.Case_Type;
begin
   Add_Test (Result, T_1);
   Add_Test (Result, T_2);
   return Result;
end HistoryTest_Suite;
