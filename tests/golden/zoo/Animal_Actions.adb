--  Animal_Actions (body)
--
--  Hand-written method bodies. Emitted once and never overwritten.

package body Animal_Actions is

   procedure Speak (Self : in out Animal.T) is
   begin
      raise Program_Error with "Animal.Speak not implemented";
   end Speak;


end Animal_Actions;
