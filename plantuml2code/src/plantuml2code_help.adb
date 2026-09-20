with Ada.Text_IO;                         use Ada.Text_IO;
with Ada.Characters.Handling;             use Ada.Characters.Handling;

with Plantuml2code_Config;
with PlantUML2Code_Ansi;      use PlantUML2Code_Ansi;

package body PlantUML2Code_Help is

   Program_Name : constant String := Plantuml2code_Config.Crate_Name;
   Version      : constant String := Plantuml2code_Config.Crate_Version;

   procedure Print_Header (F : File_Type) is
   begin
      Put_Line (F, Bold (Program_Name & " " & Version));
      Put_Line (F, "Parse PlantUML diagrams and emit them in a "
                & "chosen format.");
   end Print_Header;

   procedure Print_Usage (F : File_Type) is
   begin
      Put_Line (F, Bold ("Usage:"));
      Put_Line (F, "  " & Program_Name
                & " <command> [options] <file>...");
      New_Line (F);
      Put_Line (F, Bold ("Commands:"));
      Put_Line (F, "  " & Cyan ("dump")
                & "     Parse each file and emit it.");
      Put_Line (F, "  " & Cyan ("kind")
                & "     Print the detected diagram kind.");
      Put_Line (F, "  " & Cyan ("help")
                & "     Show help. " & Dim ("help <command>")
                & " for detail.");
      Put_Line (F, "  " & Cyan ("version")
                & "  Show version and exit.");
      New_Line (F);
      Put_Line (F, Bold ("Options:"));
      Put_Line (F, "  -f, --format=<fmt>      Output format. "
                & Dim ("Default: text"));
      Put_Line (F, "  -o, --output=<dir>      Directory for generated "
                & "files. " & Dim ("ada only"));
      Put_Line (F, "  -t, --templates=<dir>   Search <dir> first for "
                & "templates.");
      Put_Line (F, "      --color=<when>      auto | always | never");
      Put_Line (F, "  -h, --help              Same as 'help'.");
      Put_Line (F, "  -V, --version           Same as 'version'.");
      New_Line (F);
      Put_Line (F, Bold ("Files:"));
      Put_Line (F, "  A file argument of " & Cyan ("-")
                & " reads from standard input.");
      New_Line (F);
      Put_Line (F, Bold ("Examples:"));
      Put_Line (F, "  " & Dim ("$") & " " & Program_Name
                & " dump diagram.puml");
      Put_Line (F, "  " & Dim ("$") & " " & Program_Name
                & " dump -f json diagram.puml");
      Put_Line (F, "  " & Dim ("$") & " " & Program_Name
                & " dump -f ada -o ./gen diagram.puml");
      Put_Line (F, "  " & Dim ("$") & " cat diagram.puml | "
                & Program_Name & " dump -");
   end Print_Usage;

   procedure Print_Topic (Topic : String) is
      T : constant String := To_Lower (Topic);
   begin
      if T = "" or else T = "dump" then
         Put_Line (Bold ("dump") & " — parse and emit a diagram");
         Put_Line ("  Usage: " & Program_Name
                   & " dump [options] <file>...");
         New_Line;
         Put_Line ("  Reads each file as PlantUML, decides whether it "
                   & "is a state");
         Put_Line ("  diagram or a class diagram, and emits it in the "
                   & "chosen format.");
         New_Line;
         Put_Line ("  Options:");
         Put_Line ("    -f, --format=<fmt>      " & Dim ("text (default)")
                   & ", json, ada");
         Put_Line ("    -o, --output=<dir>      destination for "
                   & "generated files " & Dim ("(ada only)"));
         Put_Line ("    -t, --templates=<dir>   override template "
                   & "search path");
         New_Line;
         Put_Line ("  Formats:");
         Put_Line ("    text   " & Icon_State_Simple
                   & "  Human-readable summary.");
         Put_Line ("    json   {}  Machine-readable JSON.");
         Put_Line ("    ada    ◇  Ada source with an HSM runtime.");

      elsif T = "kind" then
         Put_Line (Bold ("kind") & " — detect the diagram kind");
         Put_Line ("  Usage: " & Program_Name & " kind <file>...");
         New_Line;
         Put_Line ("  Prints one of " & Cyan ("UNKNOWN")
                   & ", " & Cyan ("STATE_DIAGRAM")
                   & ", or " & Cyan ("CLASS_DIAGRAM")
                   & " for each file.");
         Put_Line ("  Useful in scripts to dispatch on diagram type.");

      elsif T = "help" then
         Put_Line (Bold ("help") & " — show help");
         Put_Line ("  Usage: " & Program_Name
                   & " help [<command>]");
         New_Line;
         Put_Line ("  With no argument, prints the top-level summary.");
         Put_Line ("  With a command name, prints detailed help for it.");

      elsif T = "version" then
         Put_Line (Bold ("version") & " — print version");
         Put_Line ("  Usage: " & Program_Name & " version");
         New_Line;
         Put_Line ("  Prints " & Program_Name & " " & Version
                   & " and exits.");

      else
         raise Constraint_Error with "unknown help topic: " & Topic;
      end if;
   end Print_Topic;

end PlantUML2Code_Help;
