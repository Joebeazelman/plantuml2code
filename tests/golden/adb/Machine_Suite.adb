with AUnit.Test_Cases;
with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Machine_Tests;
with Address_Resolution_Machine_Tests;
with Execute_Explicit_Command_Machine_Tests;
with Autopolling_Machine_Tests;
with SRQ_Resolution_Machine_Tests;

function Machine_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
   type Ref_1 is
     access AUnit.Test_Cases.Test_Case'Class;
   T_1 : constant Ref_1 :=
     new Machine_Tests.Case_Type;
   type Ref_2 is
     access AUnit.Test_Cases.Test_Case'Class;
   T_2 : constant Ref_2 :=
     new Address_Resolution_Machine_Tests.Case_Type;
   type Ref_3 is
     access AUnit.Test_Cases.Test_Case'Class;
   T_3 : constant Ref_3 :=
     new Execute_Explicit_Command_Machine_Tests.Case_Type;
   type Ref_4 is
     access AUnit.Test_Cases.Test_Case'Class;
   T_4 : constant Ref_4 :=
     new Autopolling_Machine_Tests.Case_Type;
   type Ref_5 is
     access AUnit.Test_Cases.Test_Case'Class;
   T_5 : constant Ref_5 :=
     new SRQ_Resolution_Machine_Tests.Case_Type;
begin
   Add_Test (Result, T_1);
   Add_Test (Result, T_2);
   Add_Test (Result, T_3);
   Add_Test (Result, T_4);
   Add_Test (Result, T_5);
   return Result;
end Machine_Suite;
