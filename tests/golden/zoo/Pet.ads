--  Pet (interface)
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  ---------------------------------------------------------------------
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package Pet is

   type T is interface;

   function Name (Self : in out T) return Unbounded_String is abstract;

end Pet;
