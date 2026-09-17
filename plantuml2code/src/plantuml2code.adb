--  plantuml2code -- parse a PlantUML diagram and emit it in the
--  requested output format.

with Ada.Command_Line;                    use Ada.Command_Line;
with Ada.Text_IO;                         use Ada.Text_IO;
with Ada.Strings.Unbounded;               use Ada.Strings.Unbounded;
with Ada.Exceptions;

with PlantUML;
with PlantUML.States;
with PlantUML.Classes;

with PlantUML2Code_Formats;               use PlantUML2Code_Formats;
with PlantUML2Code_Template_Bindings;

with PlantUML2Code_Formats;               use PlantUML2Code_Formats;
with PlantUML2Code_Template_Path;
with PlantUML2Code_Template_Bindings;

procedure PlantUML2Code is

   Fmt           : Format := Text;
   Templates_Dir : Unbounded_String := Null_Unbounded_String;
   Out_Dir       : Unbounded_String := To_Unbounded_String (".");

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
               Emit_Classes (Fmt, D);
            end;
         when PlantUML.Unknown =>
            Put_Line (Standard_Error,
                      "error: unrecognised diagram in " & Path);
            Set_Exit_Status (Failure);
      end case;
   end Cmd_Dump;

   procedure Cmd_Kind (Path : String) is
      Src : constant String := Read_All (Path);
   begin
      Put_Line (PlantUML.Detect_Kind (Src)'Image);
   end Cmd_Kind;

   procedure Usage (To_Stdout : Boolean := False) is
      procedure P (S : String) is
      begin
         if To_Stdout then
            Put_Line (Standard_Output, S);
         else
            Put_Line (Standard_Error, S);
         end if;
      end P;
   begin
      P ("usage: plantuml2code <command> [options] <file>...");
      P ("");
      P ("Commands:");
      P ("  kind    print the detected diagram kind only");
      P ("  dump    parse and emit the diagram");
      P ("  help    show this message");
      P ("");
      P ("Options:");
      P ("  -h, --help              show this help");
      P ("  -f, --format=<fmt>      text (default), json, ada");
      P ("  -t, --templates=<dir>   search <dir> first for templates");
      P ("  -o, --output=<dir>      write generated files into <dir>");
      P ("");
      P ("A file argument of '-' reads from standard input.");
   end Usage;

   type Command_Kind is (Cmd_None, Cmd_Dump, Cmd_Kind, Cmd_Help);

   function Parse_Command (S : String) return Command_Kind is
   begin
      if S = "dump" then
         return Cmd_Dump;
      elsif S = "kind" then
         return Cmd_Kind;
      elsif S = "help" or else S = "-h" or else S = "--help" then
         return Cmd_Help;
      else
         return Cmd_None;
      end if;
   end Parse_Command;

   Cmd    : Command_Kind := Cmd_None;
   Files  : array (1 .. Argument_Count) of Unbounded_String;
   NFiles : Natural := 0;

   procedure Set_Format (From : String) is
   begin
      Fmt := Parse (From);
   exception
      when Constraint_Error =>
         Put_Line (Standard_Error,
                   "error: unknown format '" & From & "'");
         Set_Exit_Status (Failure);
   end Set_Format;

begin

   PlantUML2Code_Template_Bindings.Register_Filters;

   --  Single-pass argument parsing with lookahead.
   declare
      I : Positive := 1;
   begin
      while I <= Argument_Count loop
         declare
            A : constant String := Argument (I);
         begin
            if Parse_Command (A) /= Cmd_None then
               if Cmd /= Cmd_None then
                  Put_Line (Standard_Error, "error: multiple commands");
                  Usage;
                  Set_Exit_Status (Failure);
                  return;
               end if;
               Cmd := Parse_Command (A);
               I := I + 1;

            elsif A = "-f" or else A = "--format" then
               if I = Argument_Count then
                  Put_Line (Standard_Error,
                            "error: " & A & " requires a value");
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

            elsif A = "-o" or else A = "--output" then
               if I = Argument_Count then
                  Put_Line (Standard_Error,
                            "error: " & A & " requires a value");
                  Set_Exit_Status (Failure);
                  return;
               end if;
               Out_Dir := To_Unbounded_String (Argument (I + 1));
               I := I + 2;

            elsif A = "-t" or else A = "--templates" then
               if I = Argument_Count then
                  Put_Line (Standard_Error,
                            "error: " & A & " requires a value");
                  Set_Exit_Status (Failure);
                  return;
               end if;
               Templates_Dir :=
                 To_Unbounded_String (Argument (I + 1));
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

            else
               NFiles := NFiles + 1;
               Files (NFiles) := To_Unbounded_String (A);
               I := I + 1;
            end if;
         end;
      end loop;
   end;

   --  Apply template path override if supplied.
   if Length (Templates_Dir) > 0 then
      PlantUML2Code_Template_Path.Set_Override
        (To_String (Templates_Dir));
   end if;

   PlantUML2Code_Formats.Set_Output_Dir (To_String (Out_Dir));

   if Cmd = Cmd_None or else Cmd = Cmd_Help then
      Usage (To_Stdout => (Cmd = Cmd_Help));
      Set_Exit_Status (if Cmd = Cmd_Help then Success else Failure);
      return;
   end if;

   if NFiles = 0 then
      Put_Line (Standard_Error, "error: no input files");
      Usage;
      Set_Exit_Status (Failure);
      return;
   end if;

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
               Put_Line (Standard_Error,
                         "error [Name_Error]: cannot open '"
                         & Path & "'");
               Set_Exit_Status (Failure);
            when PlantUML.Parse_Error =>
               Put_Line (Standard_Error,
                         "error [Parse_Error]: parse failure in '"
                         & Path & "'");
               Set_Exit_Status (Failure);
            when E : others =>
               Put_Line (Standard_Error,
                         "error ["
                         & Ada.Exceptions.Exception_Name (E)
                         & "]: "
                         & Ada.Exceptions.Exception_Message (E));
               Set_Exit_Status (Failure);
         end;
      end;
   end loop;

   Set_Exit_Status (Success);
end PlantUML2Code;
