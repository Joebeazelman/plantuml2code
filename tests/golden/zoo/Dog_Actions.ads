--  Dog_Actions
--
--  Hand-written method bodies for Dog.
--  Emitted once and never overwritten.

with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Animal;
with Pet;

with Dog;

package Dog_Actions is

   procedure Fetch (Self : in out Dog.T);
   procedure Move (Self : in out Dog.T);
   function Name (Self : in out Dog.T) return Unbounded_String;

end Dog_Actions;
