--  Dog (body)
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  ---------------------------------------------------------------------

with Dog_Actions;

package body Dog is

   procedure Fetch (Self : in out T) is
   begin
      Dog_Actions.Fetch (Self);
   end Fetch;

   procedure Move (Self : in out T) is
   begin
      Dog_Actions.Move (Self);
   end Move;

   function Name (Self : in out T) return Unbounded_String is
   begin
      return Dog_Actions.Name (Self);
   end Name;

   overriding
   function Class_Name (Self : T) return String is
      pragma Unreferenced (Self);
   begin
      return "Dog";
   end Class_Name;

end Dog;
