--  Animal
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
--  ---------------------------------------------------------------------
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package Animal is

   type T is abstract tagged record
      Attr_name : Unbounded_String;
   end record;

   procedure Speak (Self : in out T);
   procedure Move (Self : in out T) is abstract;

end Animal;
