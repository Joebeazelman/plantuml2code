--  Command implementations. Each returns True on success; on failure
--  an error has already been written to Standard_Error.

with Uml2Code_Formats;

package Uml2Code_Commands is

   function Run_Dump
     (Path : String;
      Fmt  : Uml2Code_Formats.Format) return Boolean;

   function Run_Kind (Path : String) return Boolean;

end Uml2Code_Commands;
