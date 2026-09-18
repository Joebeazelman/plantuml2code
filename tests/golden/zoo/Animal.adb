--  Animal (body)
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  ---------------------------------------------------------------------

with Animal_Actions;

package body Animal is

   procedure Speak (Self : in out T) is
   begin
      Animal_Actions.Speak (Self);
   end Speak;


end Animal;
