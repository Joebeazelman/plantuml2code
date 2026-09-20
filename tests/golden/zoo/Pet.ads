--  Pet (interface)
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  ---------------------------------------------------------------------
with Class_Runtime;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package Pet is

   type T is limited interface and Class_Runtime.Object;

   function Name (Self : in out T) return Unbounded_String is abstract;
   overriding
   function Class_Name (Self : T) return String is abstract;

end Pet;
