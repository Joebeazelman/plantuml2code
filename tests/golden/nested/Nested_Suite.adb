with AUnit.Test_Cases;
with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Nested_Tests;
with Running_Machine_Tests;

function Nested_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
   type Ref_1 is access Test_Case'Class;
   T_1 : Ref_1 :=
     new Nested_Tests.Case_Type;
   type Ref_2 is access Test_Case'Class;
   T_2 : Ref_2 :=
     new Running_Machine_Tests.Case_Type;
begin
   Add_Test (Result, T_1);
   Add_Test (Result, T_2);
   return Result;
end Nested_Suite;
