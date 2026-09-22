---------------------------------------------------------------------
--  Animals
---------------------------------------------------------------------
with Animals.Operations;

package body Animals is

procedure Speak (Self : in out Animal) is
begin
   Operations.Speak (Self);
end Speak;

procedure Fetch (Self : in out Dog) is
begin
   Operations.Fetch (Self);
end Fetch;

overriding
procedure Move (Self : in out Dog) is
begin
   Operations.Move (Self);
end Move;

overriding
function Name (Self : in out Dog) return Unbounded_String is
begin
   return Operations.Name (Self);
end Name;

end Animals;
