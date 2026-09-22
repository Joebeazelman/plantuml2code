---------------------------------------------------------------------
--  Animals
---------------------------------------------------------------------

with Zoo;  use Zoo;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package Animals is

   type Color is (Red, Green, Blue);

   type Pet is limited interface;

   function Name (Self : in out Pet) return Unbounded_String is abstract;

   type Animal is abstract tagged record
      Attr_Name : Unbounded_String;
   end record;

   procedure Speak (Self : in out Animal);

   procedure Move (Self : in out Animal) is abstract;

   --  A loyal companion.
   type Dog is new Animal and Pet with record
      Attr_Toy : access Toy'Class;
      Attr_Color : Color;
   end record;

   procedure Fetch (Self : in out Dog);

   overriding
   procedure Move (Self : in out Dog);

   overriding
   function Name (Self : in out Dog) return Unbounded_String;

end Animals;
