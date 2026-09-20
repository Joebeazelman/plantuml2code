--  Dog_Actions (body)
--
--  Hand-written method bodies. Emitted once and never overwritten.

package body Dog_Actions is

   procedure Fetch (Self : in out Dog.T) is
   begin
      raise Program_Error with "Dog.Fetch not implemented";
   end Fetch;

   procedure Move (Self : in out Dog.T) is
   begin
      raise Program_Error with "Dog.Move not implemented";
   end Move;

   function Name (Self : in out Dog.T) return Unbounded_String is
   begin
      raise Program_Error with "Dog.Name not implemented";
      return Null_Unbounded_String;
   end Name;


end Dog_Actions;
