--  Color (body, enumeration)

package body Color is

   function Class_Name (Self : T) return String is
      pragma Unreferenced (Self);
   begin
      return "Color";
   end Class_Name;

end Color;
