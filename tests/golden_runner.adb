with Ada.Directories;
with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Strings.Fixed;     use Ada.Strings.Fixed;
with GNAT.OS_Lib;

package body Golden_Runner is

   use Ada.Containers;
   use type Ada.Directories.File_Kind;

   --  Path constants
   Inputs_Dir    : constant String := "tests/golden/inputs";
   Expected_Dir  : constant String := "tests/golden/expected";
   Actual_Dir    : constant String := "/tmp/uml2code_golden_actual";
   Generator_Cmd : constant String := "./bin/uml2code";

   --  Compare two files, return True if identical
   function Files_Are_Identical (File1, File2 : String) return Boolean is
      F1, F2 : File_Type;
      Line1, Line2 : Unbounded_String;
   begin
      if not Ada.Directories.Exists (File1)
        or else not Ada.Directories.Exists (File2)
      then
         return False;
      end if;

      Open (F1, In_File, File1);
      Open (F2, In_File, File2);

      while not End_Of_File (F1) and then not End_Of_File (F2) loop
         Line1 := To_Unbounded_String (Get_Line (F1));
         Line2 := To_Unbounded_String (Get_Line (F2));
         if Line1 /= Line2 then
            Close (F1);
            Close (F2);
            return False;
         end if;
      end loop;

      declare
         More1 : constant Boolean := not End_Of_File (F1);
         More2 : constant Boolean := not End_Of_File (F2);
      begin
         Close (F1);
         Close (F2);
         return not More1 and then not More2;
      end;
   exception
      when others =>
         if Is_Open (F1) then Close (F1); end if;
         if Is_Open (F2) then Close (F2); end if;
         return False;
   end Files_Are_Identical;

   --  Run the generator on a .puml file
   procedure Run_Generator (Puml_File, Output_Dir : String; Success : out Boolean) is
      Cmd_Args : GNAT.OS_Lib.Argument_List_Access;
      Status   : Integer;
   begin
      --  Clean output directory
      if Ada.Directories.Exists (Output_Dir) then
         Ada.Directories.Delete_Tree (Output_Dir);
      end if;
      Ada.Directories.Create_Path (Output_Dir);

      --  Build command arguments
      Cmd_Args := new GNAT.OS_Lib.Argument_List'
        (1 => new String'("gen"),
         2 => new String'("-f"),
         3 => new String'("ada"),
         4 => new String'("-o"),
         5 => new String'(Output_Dir),
         6 => new String'(Puml_File));

      --  Run generator
      Status := GNAT.OS_Lib.Spawn
        (Program_Name           => Generator_Cmd,
         Args                   => Cmd_Args.all);
      Success := (Status = 0);

      --  Free allocated strings
      for I in Cmd_Args'Range loop
         GNAT.OS_Lib.Free (Cmd_Args (I));
      end loop;
      GNAT.OS_Lib.Free (Cmd_Args);
   end Run_Generator;

   --  Compare generated output against expected
   --  Expected files are flat in tests/golden/expected/<scenario>/
   --  Actual files are in /tmp/.../<scenario>/src/
   function Compare_Directories (Expected, Actual : String) return Boolean is
      Search : Ada.Directories.Search_Type;
      Dir_Entry  : Ada.Directories.Directory_Entry_Type;
      Actual_Src : constant String := Actual & "/src";
   begin
      if not Ada.Directories.Exists (Expected) then
         return False;
      end if;

      --  Iterate through expected files
      Ada.Directories.Start_Search (Search, Expected, "");
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         if Ada.Directories.Kind (Dir_Entry) = Ada.Directories.Ordinary_File then
            declare
               Expected_File : constant String := Ada.Directories.Full_Name (Dir_Entry);
               Relative_Name : constant String := Ada.Directories.Simple_Name (Dir_Entry);
               Actual_File   : constant String := Actual_Src & "/" & Relative_Name;
            begin
               if not Files_Are_Identical (Expected_File, Actual_File) then
                  Ada.Directories.End_Search (Search);
                  return False;
               end if;
            end;
         end if;
      end loop;
      Ada.Directories.End_Search (Search);

      return True;
   end Compare_Directories;

   --  Extract scenario name from .puml filename
   function Scenario_Name_From_File (File_Path : String) return String is
      Base : constant String := Ada.Directories.Base_Name (File_Path);
   begin
      return Base;
   end Scenario_Name_From_File;

   function Run_Golden_Test (Scenario_Name : String) return Golden_Test_Result is
      Result : Golden_Test_Result;
      Puml_File : constant String := Inputs_Dir & "/" & Scenario_Name & ".puml";
      Expected_Subdir : constant String := Expected_Dir & "/" & Scenario_Name;
      Actual_Subdir : constant String := Actual_Dir & "/" & Scenario_Name;
      Success : Boolean;
   begin
      Result.Scenario_Name := To_Unbounded_String (Scenario_Name);

      --  Check if input file exists
      if not Ada.Directories.Exists (Puml_File) then
         Result.Result := Error;
         Result.Message := To_Unbounded_String ("Input file not found: " & Puml_File);
         return Result;
      end if;

      --  Check if expected directory exists
      if not Ada.Directories.Exists (Expected_Subdir) then
         Result.Result := Error;
         Result.Message := To_Unbounded_String ("Expected directory not found: " & Expected_Subdir);
         return Result;
      end if;

      --  Run generator
      Run_Generator (Puml_File, Actual_Subdir, Success);
      if not Success then
         Result.Result := Error;
         Result.Message := To_Unbounded_String ("Generator failed");
         return Result;
      end if;

      --  Compare output
      if Compare_Directories (Expected_Subdir, Actual_Subdir) then
         Result.Result := Pass;
         Result.Message := To_Unbounded_String ("Output matches expected");
      else
         Result.Result := Fail;
         Result.Message := To_Unbounded_String ("Output differs from expected");
      end if;

      return Result;
   end Run_Golden_Test;

   function Run_All_Golden_Tests return Result_Vectors.Vector is
      Results : Result_Vectors.Vector;
      Search : Ada.Directories.Search_Type;
      Dir_Entry  : Ada.Directories.Directory_Entry_Type;
   begin
      if not Ada.Directories.Exists (Inputs_Dir) then
         declare
            R : Golden_Test_Result;
         begin
            R.Scenario_Name := To_Unbounded_String ("ALL");
            R.Result := Error;
            R.Message := To_Unbounded_String ("Inputs directory not found: " & Inputs_Dir);
            Results.Append (R);
            return Results;
         end;
      end if;

      Ada.Directories.Start_Search (Search, Inputs_Dir, "*.puml");
      while Ada.Directories.More_Entries (Search) loop
         Ada.Directories.Get_Next_Entry (Search, Dir_Entry);
         if Ada.Directories.Kind (Dir_Entry) = Ada.Directories.Ordinary_File then
            declare
               Scenario : constant String :=
                 Scenario_Name_From_File (Ada.Directories.Full_Name (Dir_Entry));
               R : constant Golden_Test_Result := Run_Golden_Test (Scenario);
            begin
               Results.Append (R);
            end;
         end if;
      end loop;
      Ada.Directories.End_Search (Search);

      return Results;
   end Run_All_Golden_Tests;

end Golden_Runner;
