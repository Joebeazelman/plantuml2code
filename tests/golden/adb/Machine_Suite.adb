with AUnit.Test_Suites;  use AUnit.Test_Suites;
with Machine_Tests;
with ADB_Reset_Machine_Tests;
with Address_Resolution_Machine_Tests;
with Execute_Explicit_Command_Machine_Tests;
with Autopolling_Machine_Tests;
with SRQ_Resolution_Machine_Tests;

function Machine_Suite return Access_Test_Suite is
   Result : constant Access_Test_Suite := new Test_Suite;
begin
   Add_Test (Result, new Machine_Tests.Case_Type);
   Add_Test (Result, new ADB_Reset_Machine_Tests.Case_Type);
   Add_Test (Result, new Address_Resolution_Machine_Tests.Case_Type);
   Add_Test (Result, new Execute_Explicit_Command_Machine_Tests.Case_Type);
   Add_Test (Result, new Autopolling_Machine_Tests.Case_Type);
   Add_Test (Result, new SRQ_Resolution_Machine_Tests.Case_Type);
   return Result;
end Machine_Suite;
