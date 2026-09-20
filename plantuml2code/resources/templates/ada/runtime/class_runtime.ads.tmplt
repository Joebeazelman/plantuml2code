--  class_runtime.ads
--
--  Abstract root for every generated class. Emitted once.
--
--  Declared as a limited interface so that generated interfaces can
--  extend it (Ada interfaces may only derive from other interfaces),
--  and so generated tagged types can implement it.

package Class_Runtime is
   pragma Preelaborate;

   type Object is limited interface;

   function Class_Name (Self : Object) return String is abstract;

end Class_Runtime;
