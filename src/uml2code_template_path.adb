with Ada.Directories;              use Ada.Directories;
with Ada.Environment_Variables;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;        use Ada.Strings.Unbounded;
with Ada.Text_IO;
with Ada.Command_Line;

package body Uml2Code_Template_Path is

   Override : Unbounded_String := Null_Unbounded_String;
   Ada_Comment_Wrap : Positive := 78;

   function Comment_Wrap return Positive is (Ada_Comment_Wrap);

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

   --  ---------------------------------------------------------------
   --  Config parsing
   --  ---------------------------------------------------------------
   --
   --  Flat `key = value` format. '#' begins a comment. Blank lines
   --  are skipped. Values are taken verbatim after the first '=' and
   --  trimmed of surrounding whitespace. `templates_dir` and
   --  `ada.comment_wrap` are recognised; unknown keys are ignored.

   function Trim (S : String) return String is
     (Ada.Strings.Fixed.Trim (S, Ada.Strings.Both));

   function Parse_Config (Content     : String;
                          Source_Name : String) return String
   is
      Result : Unbounded_String := Null_Unbounded_String;
      Line_No : Natural := 0;
      Start   : Natural := Content'First;
      Stop    : Natural;

      procedure Handle_Line (Raw : String) is
         Line : constant String := Trim (Raw);
         Eq   : constant Natural := Ada.Strings.Fixed.Index (Line, "=");
      begin
         if Line'Length = 0 or else Line (Line'First) = '#' then
            return;
         end if;
         if Eq = 0 then
            raise Config_Error with
              Source_Name & ":" & Line_No'Image
              & ": missing '=' in config line";
         end if;
         declare
            Key : constant String := Trim (Line (Line'First .. Eq - 1));
            Val : constant String := Trim (Line (Eq + 1 .. Line'Last));
         begin
            if Key = "templates_dir" then
               Result := To_Unbounded_String (Val);
            elsif Key = "ada.comment_wrap" then
               declare
                  Width : Natural;
               begin
                  Width := Natural'Value (Val);
                  if Width < 4 then
                     raise Config_Error with
                       Source_Name & ":" & Line_No'Image
                       & ": ada.comment_wrap must be at least 4";
                  end if;
                  Ada_Comment_Wrap := Positive (Width);
               exception
                  when Constraint_Error =>
                     raise Config_Error with
                       Source_Name & ":" & Line_No'Image
                       & ": invalid ada.comment_wrap value '" & Val & "'";
               end;
            end if;
         end;
      end Handle_Line;

   begin
      if Content'Length = 0 then
         return "";
      end if;

      for I in Content'Range loop
         if Content (I) = ASCII.LF then
            Line_No := Line_No + 1;
            Stop := I - 1;
            if Stop >= Start then
               Handle_Line (Content (Start .. Stop));
            end if;
            Start := I + 1;
         end if;
      end loop;

      --  Trailing line without a newline.
      if Start <= Content'Last then
         Line_No := Line_No + 1;
         Handle_Line (Content (Start .. Content'Last));
      end if;

      return To_String (Result);
   end Parse_Config;

   function Read_File (Path : String) return String is
      F : Ada.Text_IO.File_Type;
      R : Unbounded_String;
   begin
      Ada.Text_IO.Open (F, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (F) loop
         Append (R, Ada.Text_IO.Get_Line (F));
         Append (R, ASCII.LF);
      end loop;
      Ada.Text_IO.Close (F);
      return To_String (R);
   exception
      when Ada.Text_IO.Name_Error =>
         return "";
   end Read_File;

   procedure Load_Config is
      function Home_Config return String is
      begin
         if Ada.Environment_Variables.Exists ("HOME") then
            return Slash
              (Slash (Slash (Ada.Environment_Variables.Value ("HOME"),
                             ".config"),
                      "uml2code"),
               "config");
         end if;
         return "";
      exception
         when others =>
            return "";
      end Home_Config;

      procedure Try (Path : String) is
      begin
         if Path'Length = 0 then
            return;
         end if;
         declare
            Content : constant String := Read_File (Path);
            Val     : constant String :=
              (if Content'Length > 0
               then Parse_Config (Content, Path) else "");
         begin
            if Val'Length > 0 then
               Set_Override (Val);
            end if;
         end;
      end Try;
   begin
      --  CLI already won; don't override it.
      if Length (Override) > 0 then
         return;
      end if;
      Try (Current_Directory & "/uml2code.conf");
      if Length (Override) = 0 then
         Try (Home_Config);
      end if;
   end Load_Config;

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
      if Ada.Environment_Variables.Exists ("UML2CODE_TEMPLATES") then
         declare
            Root : constant String :=
              Ada.Environment_Variables.Value
                ("UML2CODE_TEMPLATES");
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

end Uml2Code_Template_Path;
