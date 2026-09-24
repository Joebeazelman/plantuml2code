with AUnit.Test_Cases;

package SRQ_Resolution_Machine_Tests is
   type Case_Type is new AUnit.Test_Cases.Test_Case with null record;
   overriding
   procedure Register_Tests (T : in out Case_Type);
   overriding
   function Name (T : Case_Type) return AUnit.Message_String;
end SRQ_Resolution_Machine_Tests;
