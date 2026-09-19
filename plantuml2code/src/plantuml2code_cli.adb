with Ada.Command_Line;                 use Ada.Command_Line;
with Ada.Text_IO;                      use Ada.Text_IO;
with Ada.Strings.Unbounded;            use Ada.Strings.Unbounded;

with Plantuml2code_Config;
with PlantUML2Code_Formats;
with PlantUML2Code_Ansi;

package body PlantUML2Code_CLI is

   Error_Prefix : constant String :=
     Plantuml2code_Config.Crate_Name & ": error: ";
   Hint_Prefix  : constant String := "       ";

   Result : Parse_Result;

   procedure Fail (Msg : String) is
   begin
      Put_Line (Standard_Error, Error_Prefix & Msg);
      Result.Ok := False;
   end Fail;

   procedure Hint (Msg : String) is
   begin
      Put_Line (Standard_Error, Hint_Prefix & Msg);
   end Hint;

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
      else
         return Cmd_None;
      end if;
   end Parse_Command;

   procedure Set_Format (S : String) is
   begin
      Result.Format := PlantUML2Code_Formats.Parse (S);
   exception
      when Constraint_Error =>
         Fail ("unknown format '" & S & "'");
         Hint ("valid formats: text, json, ada");
   end Set_Format;

   procedure Set_Color (S : String) is
   begin
      if S = "auto" then
         Result.Color := PlantUML2Code_Ansi.Auto;
      elsif S = "always" then
         Result.Color := PlantUML2Code_Ansi.Always;
      elsif S = "never" then
         Result.Color := PlantUML2Code_Ansi.Never;
      else
         Fail ("unknown color mode '" & S & "'");
         Hint ("valid modes: auto, always, never");
      end if;
   end Set_Color;

   function Parse return Parse_Result is
   begin
      Result := (others => <>);

      declare
         I : Positive := 1;
      begin
         while I <= Argument_Count loop
            declare
               A : constant String := Argument (I);
            begin
               --  Command word
               if Parse_Command (A) /= Cmd_None then
                  if Result.Cmd /= Cmd_None then
                     Fail ("multiple commands given");
                     return Result;
                  end if;
                  Result.Cmd := Parse_Command (A);
                  I := I + 1;

                  --  help consumes one optional topic word.
                  --  The word may coincide with a command name.
                  if Result.Cmd = Cmd_Help
                    and then I <= Argument_Count
                    and then Argument (I)'Length > 0
                    and then Argument (I) (Argument (I)'First) /= '-'
                  then
                     Result.Help_Topic :=
                       To_Unbounded_String (Argument (I));
                     I := I + 1;
                  end if;

               elsif A = "-h" or else A = "--help" then
                  Result.Cmd := Cmd_Help;
                  I := I + 1;

               elsif A = "-V" or else A = "--version" then
                  Result.Cmd := Cmd_Version;
                  I := I + 1;

               elsif A = "-f" or else A = "--format" then
                  if I = Argument_Count then
                     Fail (A & " requires a value");
                     return Result;
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
                     return Result;
                  end if;
                  Result.Templates_Dir :=
                    To_Unbounded_String (Argument (I + 1));
                  I := I + 2;

               elsif A'Length > 12
                 and then A (A'First .. A'First + 11) = "--templates="
               then
                  Result.Templates_Dir :=
                    To_Unbounded_String (A (A'First + 12 .. A'Last));
                  I := I + 1;

               elsif A'Length > 2
                 and then A (A'First .. A'First + 1) = "-t"
               then
                  Result.Templates_Dir :=
                    To_Unbounded_String (A (A'First + 2 .. A'Last));
                  I := I + 1;

               elsif A = "-o" or else A = "--output" then
                  if I = Argument_Count then
                     Fail (A & " requires a value");
                     return Result;
                  end if;
                  Result.Out_Dir :=
                    To_Unbounded_String (Argument (I + 1));
                  Result.Out_Set := True;
                  I := I + 2;

               elsif A'Length > 9
                 and then A (A'First .. A'First + 8) = "--output="
               then
                  Result.Out_Dir :=
                    To_Unbounded_String (A (A'First + 9 .. A'Last));
                  Result.Out_Set := True;
                  I := I + 1;

               elsif A'Length > 2
                 and then A (A'First .. A'First + 1) = "-o"
               then
                  Result.Out_Dir :=
                    To_Unbounded_String (A (A'First + 2 .. A'Last));
                  Result.Out_Set := True;
                  I := I + 1;

               elsif A = "--color" then
                  if I = Argument_Count then
                     Fail (A & " requires a value");
                     return Result;
                  end if;
                  Set_Color (Argument (I + 1));
                  I := I + 2;

               elsif A'Length > 8
                 and then A (A'First .. A'First + 7) = "--color="
               then
                  Set_Color (A (A'First + 8 .. A'Last));
                  I := I + 1;

               elsif A'Length > 0
                 and then A (A'First) = '-'
                 and then A /= "-"
               then
                  Fail ("unknown option '" & A & "'");
                  Hint ("run '" & Plantuml2code_Config.Crate_Name
                        & " help'");
                  return Result;

               else
                  Result.Files.Append (To_Unbounded_String (A));
                  I := I + 1;
               end if;
            end;
         end loop;
      end;

      return Result;
   end Parse;

end PlantUML2Code_CLI;
