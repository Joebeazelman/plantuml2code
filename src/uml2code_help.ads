--  All user-facing help text.

with Ada.Text_IO;

package Uml2Code_Help is

   procedure Print_Header (F : Ada.Text_IO.File_Type);
   --  Name and one-line description.

   procedure Print_Usage (F : Ada.Text_IO.File_Type);
   --  Command summary, options, examples.

   procedure Print_Topic (Topic : String);
   --  Detailed help for one command. Prints to Standard_Output.
   --  Unknown topics raise Constraint_Error.

end Uml2Code_Help;
