--  Command implementations. Each returns True on success; on failure
--  an error has already been written to Standard_Error.

with PlantUML2Code_Formats;

package PlantUML2Code_Commands is

   function Run_Dump
     (Path : String;
      Fmt  : PlantUML2Code_Formats.Format) return Boolean;

   function Run_Kind (Path : String) return Boolean;

end PlantUML2Code_Commands;
