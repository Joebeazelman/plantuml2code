with AUnit.Test_Cases;
with AUnit.Test_Suites;  use AUnit.Test_Suites;
with HistoryTest_Tests;
with Outer_Machine_Tests;
with Middle_Machine_Tests;
with Inner_Machine_Tests;

function HistoryTest_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
   type Ref_1 is access Test_Case'Class;
   T_1 : Ref_1 :=
     new HistoryTest_Tests.Case_Type;
   type Ref_2 is access Test_Case'Class;
   T_2 : Ref_2 :=
     new Outer_Machine_Tests.Case_Type;
   type Ref_3 is access Test_Case'Class;
   T_3 : Ref_3 :=
     new Middle_Machine_Tests.Case_Type;
   type Ref_4 is access Test_Case'Class;
   T_4 : Ref_4 :=
     new Inner_Machine_Tests.Case_Type;
begin
   Add_Test (Result, T_1);
   Add_Test (Result, T_2);
   Add_Test (Result, T_3);
   Add_Test (Result, T_4);
   return Result;
end HistoryTest_Suite;
