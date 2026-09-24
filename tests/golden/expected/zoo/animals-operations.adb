package body Animals.Operations is

   procedure Speak (Self : in out Animal) is
   begin
      null;
   end Speak;

   procedure Fetch (Self : in out Dog) is
   begin
      null;
   end Fetch;

   procedure Move (Self : in out Dog) is
   begin
      null;
   end Move;

   function Name (Self : in out Dog) return Unbounded_String is
   begin
      raise Program_Error with "Dog.Name not implemented";
      return Null_Unbounded_String;
   end Name;

end Animals.Operations;
