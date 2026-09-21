--  Toy
--
--  Generated from ../samples/zoo.puml on <DATE>.
--  Do not edit by hand; regenerate from the diagram instead.
-----------------------------------------------------------------------

with Class_Runtime;
with Class_Runtime;

package Toy is

   type T is new Class_Runtime.Object with null record;


   overriding
   function Class_Name (Self : T) return String;

end Toy;
