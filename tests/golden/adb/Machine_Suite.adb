with AUnit.Test_Cases;
with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Machine_Tests;
with ADB_Reset_Machine_Tests;
with Address_Resolution_Machine_Tests;
with Execute_Explicit_Command_Machine_Tests;
with Autopolling_Machine_Tests;
with SRQ_Resolution_Machine_Tests;

function Machine_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
   type Ref_1 is access Test_Case'Class;
   T_1 : Ref_1 :=
     new Machine_Tests.Case_Type;
   type Ref_2 is access Test_Case'Class;
   T_2 : Ref_2 :=
     new ADB_Reset_Machine_Tests.Case_Type;
   type Ref_3 is access Test_Case'Class;
   T_3 : Ref_3 :=
     new Address_Resolution_Machine_Tests.Case_Type;
   type Ref_4 is access Test_Case'Class;
   T_4 : Ref_4 :=
     new Execute_Explicit_Command_Machine_Tests.Case_Type;
   type Ref_5 is access Test_Case'Class;
   T_5 : Ref_5 :=
     new Autopolling_Machine_Tests.Case_Type;
   type Ref_6 is access Test_Case'Class;
   T_6 : Ref_6 :=
     new SRQ_Resolution_Machine_Tests.Case_Type;
begin
   Add_Test (Result, T_1);
   Add_Test (Result, T_2);
   Add_Test (Result, T_3);
   Add_Test (Result, T_4);
   Add_Test (Result, T_5);
   Add_Test (Result, T_6);
   return Result;
end Machine_Suite;
