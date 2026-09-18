--  Dog
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
--  ---------------------------------------------------------------------
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;
with Animal;
with Pet;

package Dog is

   type T is new Animal.T and Pet.T with null record;

   procedure Fetch (Self : in out T);
   overriding
   procedure Move (Self : in out T);
   overriding
   function Name (Self : in out T) return Unbounded_String;

end Dog;
