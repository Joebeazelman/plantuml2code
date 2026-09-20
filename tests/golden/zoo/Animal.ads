--  Animal
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
--  ---------------------------------------------------------------------

with Class_Runtime;
with Class_Runtime;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package Animal is

   type T is abstract new Class_Runtime.Object with record
      Attr_name : Unbounded_String;
   end record;

   procedure Speak (Self : in out T);
   procedure Move (Self : in out T) is abstract;

   overriding
   function Class_Name (Self : T) return String;

end Animal;
