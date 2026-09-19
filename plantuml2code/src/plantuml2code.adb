--  plantuml2code -- parse PlantUML diagrams and emit them in
--  a chosen format.
--
--  See `plantuml2code help` for usage.

with Ada.Command_Line;                    use Ada.Command_Line;
with Ada.Text_IO;                         use Ada.Text_IO;
with Ada.Strings.Unbounded;               use Ada.Strings.Unbounded;
with Ada.Directories;
with Ada.Exceptions;

with Plantuml2code_Config;

with PlantUML;
with PlantUML.States;
with PlantUML.Classes;

with PlantUML2Code_Formats;               use PlantUML2Code_Formats;
with PlantUML2Code_Template_Path;
with PlantUML2Code_Template_Bindings;

procedure PlantUML2Code is

   Version      : constant String := Plantuml2code_Config.Crate_Version;
   Program_Name : constant String := Plantuml2code_Config.Crate_Name;
   Error_Prefix : constant String := Program_Name & ": error: ";
   Hint_Prefix  : constant String := "       ";

   type Command_Kind is
     (Cmd_None, Cmd_Dump, Cmd_Kind, Cmd_Help, Cmd_Version, Cmd_List_Formats);

   Fmt           : Format := Text;
   Templates_Dir : Unbounded_String := Null_Unbounded_String;
   Out_Dir       : Unbounded_String := Null_Unbounded_String;
   Out_Set       : Boolean := False;
   Cmd           : Command_Kind := Cmd_None;
   Files         : array (1 .. Argument_Count) of Unbounded_String;
   NFiles        : Natural := 0;
   Ok            : Boolean := True;

   procedure Fail (Msg : String) is
   begin
      Put_Line (Standard_Error, Error_Prefix & Msg);
      Ok := False;
   end Fail;

   procedure Hint (Msg : String) is
   begin
      Put_Line (Standard_Error, Hint_Prefix & Msg);
   end Hint;

   function Read_All (Path : String) return String is
      Result : Unbounded_String;
      F      : File_Type;
   begin
      if Path = "-" then
         while not End_Of_File (Standard_Input) loop
            declare
               C : Character;
            begin
               Get_Immediate (Standard_Input, C);
               Append (Result, C);
            end;
         end loop;
      else
         Open (F, In_File, Path);
         while not End_Of_File (F) loop
            declare
               C : Character;
            begin
               Get_Immediate (F, C);
               Append (Result, C);
            end;
         end loop;
         Close (F);
      end if;
      return To_String (Result);
   end Read_All;

   procedure Cmd_Dump (Path : String) is
      Src  : constant String := Read_All (Path);
      Kind : constant PlantUML.Diagram_Kind := PlantUML.Detect_Kind (Src);
   begin
      case Kind is
         when PlantUML.State_Diagram =>
            declare
               D : constant PlantUML.States.State_Diagram :=
                 PlantUML.States.Parse (Src);
            begin
               Emit_States (Fmt, D, Path);
            end;
         when PlantUML.Class_Diagram =>
            declare
               D : constant PlantUML.Classes.Class_Diagram :=
                 PlantUML.Classes.Parse (Src);
            begin
               Emit_Classes (Fmt, D, Path);
            end;
         when PlantUML.Unknown =>
            Fail ("no recognised PlantUML diagram in '" & Path & "'");
            Hint ("the file must contain @startuml/@enduml");
      end case;
   end Cmd_Dump;

   procedure Cmd_Kind (Path : String) is
      Src : constant String := Read_All (Path);
   begin
      Put_Line (PlantUML.Detect_Kind (Src)'Image);
   end Cmd_Kind;

   procedure Print_Usage (F : File_Type) is
   begin
      Put_Line (F, "Usage:");
      Put_Line (F, "  " & Program_Name
                & " <command> [options] <file>...");
      New_Line (F);
      Put_Line (F, "Commands:");
      Put_Line (F, "  dump           Parse each file and emit it.");
      Put_Line (F, "  kind           Print the detected diagram kind.");
      Put_Line (F, "  help           Show this message.");
      Put_Line (F, "  version        Show version and exit.");
      Put_Line (F, "  list-formats   List available output formats.");
      New_Line (F);
      Put_Line (F, "Options:");
      Put_Line (F, "  -f, --format=<fmt>      Output format. "
                & "Default: text.");
      Put_Line (F, "  -o, --output=<dir>      Directory for generated "
                & "files (ada only).");
      Put_Line (F, "  -t, --templates=<dir>   Search <dir> first for "
                & "templates.");
      Put_Line (F, "  -h, --help              Show this message.");
      Put_Line (F, "  -V, --version           Show version and exit.");
      Put_Line (F, "      --list-formats      List available formats.");
      New_Line (F);
      Put_Line (F, "A file argument of '-' reads from standard input.");
      New_Line (F);
      Put_Line (F, "Examples:");
      Put_Line (F, "  " & Program_Name & " dump diagram.puml");
      Put_Line (F, "  " & Program_Name
                & " dump -f json diagram.puml");
      Put_Line (F, "  " & Program_Name
                & " dump -f ada -o ./generated diagram.puml");
      Put_Line (F, "  cat diagram.puml | " & Program_Name & " dump -");
   end Print_Usage;

   procedure Print_Header (F : File_Type) is
   begin
      Put_Line (F, Program_Name & " " & Version);
      Put_Line (F, "Parse PlantUML diagrams and emit them in a "
                & "chosen format.");
   end Print_Header;

   procedure Print_Formats (F : File_Type) is
   begin
      Put_Line (F, "Available formats:");
      Put_Line (F, "  text    Human-readable summary (default).");
      Put_Line (F, "  json    Machine-readable JSON.");
      Put_Line (F, "  ada     Ada HSM source (state diagrams only).");
   end Print_Formats;

   function Parse_Command (S : String) return Command_Kind is
   begin
      if S = "dump" then
         return Cmd_Dump;
      elsif S = "kind" then
         return Cmd_Kind;
      elsif S = "help" then
         return Cmd_Help;
      elsif S = "version" then
         return Cmd_Version;
      elsif S = "list-formats" then
         return Cmd_List_Formats;
      else
         return Cmd_None;
      end if;
   end Parse_Command;

   procedure Set_Format (S : String) is
   begin
      Fmt := Parse (S);
   exception
      when Constraint_Error =>
         Fail ("unknown format '" & S & "'");
         Hint ("valid formats: text, json, ada");
   end Set_Format;

begin
   declare
      I : Positive := 1;
   begin
      while I <= Argument_Count loop
         declare
            A : constant String := Argument (I);
         begin
            if Parse_Command (A) /= Cmd_None then
               if Cmd /= Cmd_None then
                  Fail ("multiple commands given");
                  Set_Exit_Status (Failure);
                  return;
               end if;
               Cmd := Parse_Command (A);
               I := I + 1;

            elsif A = "-h" or else A = "--help" then
               Cmd := Cmd_Help;
               I := I + 1;

            elsif A = "-V" or else A = "--version" then
               Cmd := Cmd_Version;
               I := I + 1;

            elsif A = "--list-formats" then
               Cmd := Cmd_List_Formats;
               I := I + 1;

            elsif A = "-f" or else A = "--format" then
               if I = Argument_Count then
                  Fail (A & " requires a value");
                  Set_Exit_Status (Failure);
                  return;
               end if;
               Set_Format (Argument (I + 1));
               I := I + 2;

            elsif A'Length > 9
              and then A (A'First .. A'First + 8) = "--format="
            then
               Set_Format (A (A'First + 9 .. A'Last));
               I := I + 1;

            elsif A'Length > 2
              and then A (A'First .. A'First + 1) = "-f"
            then
               Set_Format (A (A'First + 2 .. A'Last));
               I := I + 1;

            elsif A = "-t" or else A = "--templates" then
               if I = Argument_Count then
                  Fail (A & " requires a value");
                  Set_Exit_Status (Failure);
                  return;
               end if;
               Templates_Dir := To_Unbounded_String (Argument (I + 1));
               I := I + 2;

            elsif A'Length > 12
              and then A (A'First .. A'First + 11) = "--templates="
            then
               Templates_Dir :=
                 To_Unbounded_String (A (A'First + 12 .. A'Last));
               I := I + 1;

            elsif A'Length > 2
              and then A (A'First .. A'First + 1) = "-t"
            then
               Templates_Dir :=
                 To_Unbounded_String (A (A'First + 2 .. A'Last));
               I := I + 1;

            elsif A = "-o" or else A = "--output" then
               if I = Argument_Count then
                  Fail (A & " requires a value");
                  Set_Exit_Status (Failure);
                  return;
               end if;
               Out_Dir := To_Unbounded_String (Argument (I + 1));
               Out_Set := True;
               I := I + 2;

            elsif A'Length > 9
              and then A (A'First .. A'First + 8) = "--output="
            then
               Out_Dir :=
                 To_Unbounded_String (A (A'First + 9 .. A'Last));
               Out_Set := True;
               I := I + 1;

            elsif A'Length > 2
              and then A (A'First .. A'First + 1) = "-o"
            then
               Out_Dir :=
                 To_Unbounded_String (A (A'First + 2 .. A'Last));
               Out_Set := True;
               I := I + 1;

            elsif A'Length > 0
              and then A (A'First) = '-'
              and then A /= "-"
            then
               Fail ("unknown option '" & A & "'");
               Hint ("run '" & Program_Name
                     & " help' for the list of options");
               Set_Exit_Status (Failure);
               return;

            else
               NFiles := NFiles + 1;
               Files (NFiles) := To_Unbounded_String (A);
               I := I + 1;
            end if;
         end;
      end loop;
   end;

   if Cmd = Cmd_Help then
      Print_Header (Standard_Output);
      New_Line (Standard_Output);
      Print_Usage (Standard_Output);
      Set_Exit_Status (Success);
      return;
   elsif Cmd = Cmd_Version then
      Put_Line (Standard_Output, Program_Name & " " & Version);
      Set_Exit_Status (Success);
      return;
   elsif Cmd = Cmd_List_Formats then
      Print_Formats (Standard_Output);
      Set_Exit_Status (Success);
      return;
   end if;

   if Cmd = Cmd_None then
      Fail ("no command given");
      Print_Usage (Standard_Error);
      Set_Exit_Status (Failure);
      return;
   end if;

   if not Ok then
      Set_Exit_Status (Failure);
      return;
   end if;

   if NFiles = 0 then
      Fail ("no input files given");
      Hint ("pass one or more .puml files, or '-' for stdin");
      Set_Exit_Status (Failure);
      return;
   end if;

   if Length (Templates_Dir) > 0 then
      declare
         D : constant String := To_String (Templates_Dir);
      begin
         if not Ada.Directories.Exists (D) then
            Fail ("template directory not found: '" & D & "'");
            Set_Exit_Status (Failure);
            return;
         end if;
         PlantUML2Code_Template_Path.Set_Override (D);
      end;
   end if;

   if Out_Set then
      declare
         D : constant String := To_String (Out_Dir);
      begin
         if not Ada.Directories.Exists (D) then
            Fail ("output directory not found: '" & D & "'");
            Hint ("create it with: mkdir -p " & D);
            Set_Exit_Status (Failure);
            return;
         end if;
         PlantUML2Code_Formats.Set_Output_Dir (D);
      end;
   end if;

   if Out_Set and then Fmt /= Ada_HSM then
      Put_Line (Standard_Error,
                Program_Name & ": warning: -o is only used by "
                & "format 'ada'; ignoring for format "
                & Fmt'Image);
   end if;

   for I in 1 .. NFiles loop
      declare
         P : constant String := To_String (Files (I));
      begin
         if P /= "-" and then not Ada.Directories.Exists (P) then
            Fail ("input file not found: '" & P & "'");
            Set_Exit_Status (Failure);
            return;
         end if;
      end;
   end loop;

   PlantUML2Code_Template_Bindings.Register_Filters;

   for I in 1 .. NFiles loop
      declare
         Path : constant String := To_String (Files (I));
      begin
         begin
            case Cmd is
               when Cmd_Dump => Cmd_Dump (Path);
               when Cmd_Kind => Cmd_Kind (Path);
               when others   => null;
            end case;
         exception
            when Name_Error =>
               Fail ("cannot open '" & Path & "'");
            when PlantUML.Parse_Error =>
               Fail ("parse failure in '" & Path & "'");
            when PlantUML2Code_Template_Path.Template_Not_Found =>
               Fail ("no template found for format '"
                     & Fmt'Image & "'");
               Hint ("use -t <dir> to point at a custom template "
                     & "directory");
            when E : others =>
               Fail (Ada.Exceptions.Exception_Name (E)
                     & " while processing '" & Path & "'");
               if Ada.Exceptions.Exception_Message (E)'Length > 0 then
                  Hint (Ada.Exceptions.Exception_Message (E));
               end if;
         end;
      end;
   end loop;

   Set_Exit_Status (if Ok then Success else Failure);
end PlantUML2Code;
