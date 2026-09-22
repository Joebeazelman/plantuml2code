--  One test per concrete class: declare an instance, prove it
--  compiles and default-constructs. Behavioral tests wait until
--  the user fills in <Package>.Operations.

with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Animals;
with Zoo;

package body Zoo_Tests is

   procedure Test_Instantiate_Dog (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      X : Animals.Dog;
      pragma Unreferenced (X);
   begin
      null;
   end Test_Instantiate_Dog;

   procedure Test_Instantiate_Toy (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      X : Zoo.Toy;
      pragma Unreferenced (X);
   begin
      null;
   end Test_Instantiate_Toy;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Instantiate_Dog'Access,
                        "instantiate Animals.Dog");
      Register_Routine (T, Test_Instantiate_Toy'Access,
                        "instantiate Zoo.Toy");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Zoo");
   end Name;

end Zoo_Tests;
