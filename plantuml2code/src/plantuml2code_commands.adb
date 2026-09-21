with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;

with Plantuml2code_Config;
with UML.Model;
with PlantUML;
with PlantUML.States;
with PlantUML.Classes;
with PlantUML2Code_Model_Dump;

package body PlantUML2Code_Commands is

   use type UML.Model.Diagram_Kind;

   Program_Name : constant String := Plantuml2code_Config.Crate_Name;

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

   function Run_Dump
     (Path : String;
      Fmt  : PlantUML2Code_Formats.Format) return Boolean
   is
      Src    : constant String := Read_All (Path);
      Model  : constant UML.Model.Diagram := PlantUML.Parse (Src);
   begin
      if Model.Kind = UML.Model.Unknown then
         Put_Line (Standard_Error,
                   Program_Name & ": error: no recognised "
                   & "PlantUML diagram in '" & Path & "'");
         Put_Line (Standard_Error,
                   "       the file must contain @startuml/@enduml");
         return False;
      end if;

      case Fmt is
         when PlantUML2Code_Formats.Text =>
            PlantUML2Code_Model_Dump.Dump (Model);
         when others =>
            Put_Line (Standard_Error,
                      Program_Name & ": error: format "
                      & Fmt'Image & " not yet supported on the "
                      & "model path");
            return False;
      end case;
      return True;
   end Run_Dump;

   function Run_Kind (Path : String) return Boolean is
      Src : constant String := Read_All (Path);
   begin
      Put_Line (PlantUML.Detect_Kind (Src)'Image);
      return True;
   end Run_Kind;

end PlantUML2Code_Commands;
