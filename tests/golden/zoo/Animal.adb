--  Animal (body)
--
--  Generated from ../samples/zoo.puml on <DATE>.
-----------------------------------------------------------------------

with Animal_Actions;

package body Animal is

   procedure Speak (Self : in out T) is
   begin
      Animal_Actions.Speak (Self);
   end Speak;

   overriding
   function Class_Name (Self : T) return String is
      pragma Unreferenced (Self);
   begin
      return "Animal";
   end Class_Name;

end Animal;
