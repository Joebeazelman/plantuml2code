with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Dog;
with Animal;
with Pet;
with Color;

procedure Class_Test is
   D : Dog.T;
begin
   Put_Line ("Dog.T constructed");

   --  Sanity-check some declarations without calling raising stubs
   Put_Line ("Color literals: "
             & Color.T'Image (Color.Red) & ", "
             & Color.T'Image (Color.Green) & ", "
             & Color.T'Image (Color.Blue));

   --  Call a stub. It will raise Program_Error, and we catch it
   --  to prove the call path works.
   begin
      D.Fetch;
      Put_Line ("Fetch returned (unexpected)");
   exception
      when Program_Error =>
         Put_Line ("Fetch raised Program_Error as expected");
   end;

   --  Also try the overridden inherited methods
   begin
      D.Move;
      Put_Line ("Move returned (unexpected)");
   exception
      when Program_Error =>
         Put_Line ("Move raised Program_Error as expected");
   end;

   begin
      declare
         N : constant Unbounded_String := D.Name;
      begin
         Put_Line ("Name returned: " & To_String (N) & " (unexpected)");
      end;
   exception
      when Program_Error =>
         Put_Line ("Name raised Program_Error as expected");
   end;

   Put_Line ("Done.");
end Class_Test;
