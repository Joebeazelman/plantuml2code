---------------------------------------------------------------------
--  Animals
---------------------------------------------------------------------

with Zoo;  use Zoo;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

package Animals is

   type Color is (Red, Green, Blue);


   type Toy_Access is access all Toy'Class;

   package Toy_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Toy_Access);


   type Pet is limited interface;

   function Name (Self : in out Pet) return Unbounded_String is abstract;

   type Animal is abstract tagged record
      Attr_Name : Unbounded_String;
   end record;

   procedure Speak (Self : in out Animal);
   procedure Move (Self : in out Animal) is abstract;

   type Dog is new Animal and Pet with record
      Attr_Toy : Toy_Vectors.Vector;
      Attr_Color : Color;
   end record;

   procedure Fetch (Self : in out Dog);
   overriding
   procedure Move (Self : in out Dog);
   overriding
   function Name (Self : in out Dog) return Unbounded_String;

end Animals;
