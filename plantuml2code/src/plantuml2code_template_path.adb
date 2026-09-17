with Ada.Directories;              use Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Unbounded;        use Ada.Strings.Unbounded;

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

   --  Concatenate two path fragments with a single slash between.
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

   function Locate (Subdir : String; File : String) return String is
      CWD      : constant String := Ada.Directories.Current_Directory;
      Parent   : constant String :=
        Ada.Directories.Containing_Directory (CWD);
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

      --  1. environment
      if Ada.Environment_Variables.Exists ("PLANTUML2CODE_TEMPLATES") then
         declare
            Root : constant String :=
              Ada.Environment_Variables.Value ("PLANTUML2CODE_TEMPLATES");
            P    : constant String := Try_Under (Root, Subdir, File);
         begin
            if P'Length > 0 then
               return P;
            end if;
         end;
      end if;

      --  2. <parent-of-cwd>/resources/templates
      declare
         Root : constant String := Slash (Parent, "resources/templates");
         P    : constant String := Try_Under (Root, Subdir, File);
      begin
         if P'Length > 0 then
            return P;
         end if;
      end;

      --  3. <cwd>/resources/templates
      declare
         Root : constant String := Slash (CWD, "resources/templates");
         P    : constant String := Try_Under (Root, Subdir, File);
      begin
         if P'Length > 0 then
            return P;
         end if;
      end;

      raise Template_Not_Found with
        "template not found: " & Subdir & "/" & File;
   end Locate;

end PlantUML2Code_Template_Path;