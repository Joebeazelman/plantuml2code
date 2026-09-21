--  Dog
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
-----------------------------------------------------------------------

with Class_Runtime;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Animal;
with Pet;
with Toy;
with Color;

package Dog is

   type T is new Animal.T and Pet.T with record
      Attr_Toy : access Toy.T'Class;
      Attr_Color : Color.T;
   end record;

   procedure Fetch (Self : in out T);
   overriding
   procedure Move (Self : in out T);
   overriding
   function Name (Self : in out T) return Unbounded_String;

   overriding
   function Class_Name (Self : T) return String;

end Dog;
