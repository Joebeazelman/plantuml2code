---------------------------------------------------------------------
--  Animals.Operations
--
--  Hand-written method bodies for Animals.
--  Emitted once and never overwritten.
---------------------------------------------------------------------

with Animals;  use Animals;

package Animals.Operations is

procedure Speak (Self : in out Animal);

procedure Fetch (Self : in out Dog);

procedure Move (Self : in out Dog);

function Name (Self : in out Dog) return Unbounded_String;

end Animals.Operations;
