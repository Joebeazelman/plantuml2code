--  Generated driver. Compile-proof only.

with Ada.Text_IO; use Ada.Text_IO;
with Animals;
with Zoo;

procedure Driver is
   X_Dog : Animals.Dog;
   pragma Unreferenced (X_Dog);
   X_Toy : Zoo.Toy;
   pragma Unreferenced (X_Toy);
begin
   Put_Line ("Zoo");
end Driver;
