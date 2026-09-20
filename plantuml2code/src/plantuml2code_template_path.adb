with Ada.Directories;              use Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded;        use Ada.Strings.Unbounded;
with Ada.Command_Line;

package body PlantUML2Code_Template_Path is

   Override : Unbounded_String := Null_Unbounded_String;

   procedure Set_Override (Dir : String) is
   begin
      Override := To_Unbounded_String (Dir);
   end Set_Override;

   procedure Clear_Override is
   begin
      Override := Null_Unbounded_String;
   end Clear_Override;

   function Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path);
   end Exists;

   function Slash (A, B : String) return String is
   begin
      if A'Length = 0 then
         return B;
      elsif A (A'Last) = '/' then
         return A & B;
      else
         return A & "/" & B;
      end if;
   end Slash;

   function Try_Under (Root, Subdir, File : String) return String is
      P1 : constant String := Slash (Slash (Root, Subdir), File);
      P2 : constant String := Slash (Slash (Root, "default"), File);
   begin
      if Exists (P1) then
         return P1;
      end if;
      if Exists (P2) then
         return P2;
      end if;
      return "";
   exception
      when others =>
         return "";
   end Try_Under;

   --  Directory containing the running executable. Falls back to the
   --  current directory if the path cannot be determined.
   function Exe_Dir return String is
   begin
      if Ada.Command_Line.Command_Name'Length > 0 then
         declare
            Cmd : constant String := Ada.Command_Line.Command_Name;
            D   : constant String := Containing_Directory (Cmd);
         begin
            if D'Length > 0 then
               return D;
            end if;
         end;
      end if;
      return Current_Directory;
   exception
      when others =>
         return Current_Directory;
   end Exe_Dir;

   function Locate (Subdir : String; File : String) return String is
      CWD      : constant String := Current_Directory;
      Parent   : constant String := Containing_Directory (CWD);
      Exe      : constant String := Exe_Dir;
      Exe_Par  : constant String := Containing_Directory (Exe);

      Candidates : constant array (1 .. 6) of Unbounded_String :=
        [To_Unbounded_String (Slash (CWD,     "resources/templates")),
         To_Unbounded_String (Slash (Parent,  "resources/templates")),
         To_Unbounded_String (Slash (Exe,     "../resources/templates")),
         To_Unbounded_String (Slash (Exe,     "resources/templates")),
         To_Unbounded_String (Slash (Exe_Par, "resources/templates")),
         To_Unbounded_String (Slash (Exe_Par, "../resources/templates"))];
   begin
      --  0. CLI override
      if Length (Override) > 0 then
         declare
            P : constant String :=
              Try_Under (To_String (Override), Subdir, File);
         begin
            if P'Length > 0 then
               return P;
            end if;
         end;
      end if;

      --  1. environment variable
      if Ada.Environment_Variables.Exists ("PLANTUML2CODE_TEMPLATES") then
         declare
            Root : constant String :=
              Ada.Environment_Variables.Value
                ("PLANTUML2CODE_TEMPLATES");
            P    : constant String := Try_Under (Root, Subdir, File);
         begin
            if P'Length > 0 then
               return P;
            end if;
         end;
      end if;

      --  2. known candidate roots
      for R of Candidates loop
         declare
            P : constant String :=
              Try_Under (To_String (R), Subdir, File);
         begin
            if P'Length > 0 then
               return P;
            end if;
         end;
      end loop;

      raise Template_Not_Found with
        "template not found: " & Subdir & "/" & File
        & " (searched cwd, exe-dir, and parent-of-exe)";
   end Locate;

end PlantUML2Code_Template_Path;
