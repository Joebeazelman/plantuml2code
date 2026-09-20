--  Color (enumeration)
--
--  Generated from ../samples/zoo.puml on <DATE>.

with Class_Runtime;

package Color is

   type T is (Red, Green, Blue);

   function Class_Name (Self : T) return String;

end Color;
