--  plantuml2code -- parse PlantUML diagrams and emit them in a
--  chosen format.
--
--  This file is only the orchestration layer. Argument parsing lives
--  in PlantUML2Code_CLI, help text in PlantUML2Code_Help, and
--  command bodies in PlantUML2Code_Commands.

with Ada.Command_Line;                use Ada.Command_Line;
with Ada.Text_IO;                     use Ada.Text_IO;
with Ada.Strings.Unbounded;           use Ada.Strings.Unbounded;
with Ada.Directories;
with Ada.Exceptions;

with PlantUML;
with Plantuml2code_Config;
with PlantUML2Code_Ansi;
with PlantUML2Code_CLI;               use PlantUML2Code_CLI;
with PlantUML2Code_Commands;
with PlantUML2Code_Formats;           use PlantUML2Code_Formats;
with PlantUML2Code_Help;
with PlantUML2Code_Template_Path;
with PlantUML2Code_Template_Bindings;

procedure PlantUML2Code is

   Program_Name : constant String := Plantuml2code_Config.Crate_Name;
   Error_Prefix : constant String := Program_Name & ": error: ";
   Hint_Prefix  : constant String := "       ";

   Args : constant Parse_Result := PlantUML2Code_CLI.Parse;

   Ok : Boolean := Args.Ok;

   procedure Fail (Msg : String) is
   begin
      Put_Line (Standard_Error, Error_Prefix & Msg);
      Ok := False;
   end Fail;

   procedure Hint (Msg : String) is
   begin
      Put_Line (Standard_Error, Hint_Prefix & Msg);
   end Hint;

begin
   PlantUML2Code_Ansi.Set_Mode (Args.Color);

   if not Args.Ok then
      Set_Exit_Status (Failure);
      return;
   end if;

   --  Short-circuit commands
   case Args.Cmd is
      when Cmd_Help =>
         PlantUML2Code_Help.Print_Header (Standard_Output);
         New_Line;
         if Length (Args.Help_Topic) > 0 then
            begin
               PlantUML2Code_Help.Print_Topic
                 (To_String (Args.Help_Topic));
            exception
               when Constraint_Error =>
                  Fail ("unknown help topic '"
                        & To_String (Args.Help_Topic) & "'");
                  Hint ("run '" & Program_Name & " help'");
            end;
         else
            PlantUML2Code_Help.Print_Usage (Standard_Output);
         end if;
         Set_Exit_Status (if Ok then Success else Failure);
         return;

      when Cmd_Version =>
         Put_Line (Standard_Output,
                   Program_Name & " "
                   & Plantuml2code_Config.Crate_Version);
         Set_Exit_Status (Success);
         return;

      when Cmd_None =>
         Fail ("no command given");
         PlantUML2Code_Help.Print_Usage (Standard_Error);
         Set_Exit_Status (Failure);
         return;

      when others =>
         null;
   end case;

   --  Validation
   if Args.Files.Is_Empty then
      Fail ("no input files given");
      Hint ("pass one or more .puml files, or '-' for stdin");
      Set_Exit_Status (Failure);
      return;
   end if;

   if Length (Args.Templates_Dir) > 0 then
      declare
         D : constant String := To_String (Args.Templates_Dir);
      begin
         if not Ada.Directories.Exists (D) then
            Fail ("template directory not found: '" & D & "'");
            Set_Exit_Status (Failure);
            return;
         end if;
         PlantUML2Code_Template_Path.Set_Override (D);
      end;
   end if;

   --  No -t on the command line: read config files. CLI wins if both.
   if Length (Args.Templates_Dir) = 0 then
      begin
         PlantUML2Code_Template_Path.Load_Config;
      exception
         when PlantUML2Code_Template_Path.Config_Error =>
            Fail ("malformed config file");
            Set_Exit_Status (Failure);
            return;
      end;
   end if;

   if Args.Out_Set then
      declare
         D : constant String := To_String (Args.Out_Dir);
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

   if Args.Out_Set and then Args.Format /= Ada_HSM then
      Put_Line (Standard_Error,
                Program_Name & ": warning: -o is only used by "
                & "format 'ada'; ignoring for format "
                & Args.Format'Image);
   end if;

   for F of Args.Files loop
      declare
         P : constant String := To_String (F);
      begin
         if P /= "-" and then not Ada.Directories.Exists (P) then
            Fail ("input file not found: '" & P & "'");
            Set_Exit_Status (Failure);
            return;
         end if;
      end;
   end loop;

   --  Dispatch
   PlantUML2Code_Template_Bindings.Register_Filters;

   for F of Args.Files loop
      declare
         Path : constant String := To_String (F);
      begin
         begin
            case Args.Cmd is
               when Cmd_Dump =>
                  if not PlantUML2Code_Commands.Run_Dump
                           (Path, Args.Format)
                  then
                     Ok := False;
                  end if;
               when Cmd_Kind =>
                  if not PlantUML2Code_Commands.Run_Kind (Path) then
                     Ok := False;
                  end if;
               when others =>
                  null;
            end case;
         exception
            when Name_Error =>
               Fail ("cannot open '" & Path & "'");
            when PlantUML.Parse_Error =>
               Fail ("parse failure in '" & Path & "'");
            when PlantUML2Code_Template_Path.Template_Not_Found =>
               Fail ("no template found for format '"
                     & Args.Format'Image & "'");
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
