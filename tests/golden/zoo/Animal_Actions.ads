--  Animal_Actions
--
--  Hand-written method bodies for Animal.
--  Emitted once and never overwritten.

with Class_Runtime;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

with Animal;

package Animal_Actions is

   procedure Speak (Self : in out Animal.T);

end Animal_Actions;
