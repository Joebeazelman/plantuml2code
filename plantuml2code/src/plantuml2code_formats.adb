with Ada.Text_IO;                      use Ada.Text_IO;
with Ada.Strings.Unbounded;            use Ada.Strings.Unbounded;
with Ada.Characters.Handling;          use Ada.Characters.Handling;

with Templates_Parser;                 use Templates_Parser;

with PlantUML2Code_Utils;              use PlantUML2Code_Utils;
with PlantUML2Code_Template_Bindings;  use PlantUML2Code_Template_Bindings;
with PlantUML2Code_Ada;
with PlantUML2Code_Ada_Classes;

package body PlantUML2Code_Formats is

   Out_Dir : Unbounded_String := To_Unbounded_String (".");

   procedure Set_Output_Dir (Dir : String) is
   begin
      Out_Dir := To_Unbounded_String (Dir);
   end Set_Output_Dir;

   function Parse (S : String) return Format is
      Low : constant String := To_Lower (S);
   begin
      if Low = "text" then
         return Text;
      elsif Low = "json" then
         return Json;
      elsif Low = "ada" or else Low = "ada-hsm" then
         return Ada_HSM;
      else
         raise Constraint_Error with "unknown format: " & S;
      end if;
   end Parse;

   --  Map a Format value to its template subdirectory name.
   --  Diagram kind for template lookup. Templates live under
   --  resources/templates/<format>/<kind>/.
   type Diagram_Kind is (State, Class);

   function Subdir_For (Fmt : Format; Kind : Diagram_Kind)
                        return String is
     (case Fmt is
         when Text    => "default/" & (if Kind = State
                                       then "state" else "class"),
         when Json    => "json/"    & (if Kind = State
                                       then "state" else "class"),
         when Ada_HSM => "ada/"     & (if Kind = State
                                       then "state" else "class"));

   procedure Emit_To_Stdout
     (Subdir   : String;
      Template : String;
      T        : Translate_Set)
   is
      S : constant String := Render_Template (Subdir, Template, T);
   begin
      Put (S);
      if S'Length > 0 and then S (S'Last) /= ASCII.LF then
         New_Line;
      end if;
   end Emit_To_Stdout;

   procedure Emit_States
     (Fmt  : Format;
      D    : UML.Model.Diagram;
      Path : String := "")
   is
   begin
      case Fmt is
         when Text | Json =>
            Emit_To_Stdout
              (Subdir_For (Fmt, State), "state.tmplt", For_States (D));
         when Ada_HSM =>
            declare
               Name : constant String :=
                 (if Length (D.Id) > 0
                  then To_String (D.Id) else "Machine");
               Src : constant String :=
                 (if Path'Length > 0 then Path else Name & ".puml");
            begin
               PlantUML2Code_Ada.Generate
                 (D              => D,
                  Package_Name   => Name,
                  Source_Diagram => Src,
                  Out_Dir        => To_String (Out_Dir));
            end;
      end case;
   end Emit_States;

   procedure Emit_Classes
     (Fmt  : Format;
      D    : UML.Model.Diagram;
      Path : String := "")
   is
   begin
      case Fmt is
         when Text | Json =>
            Emit_To_Stdout
              (Subdir_For (Fmt, Class), "class.tmplt", For_Classes (D));
         when Ada_HSM =>
            PlantUML2Code_Ada_Classes.Generate
              (D              => D,
               Source_Diagram => (if Path'Length > 0
                                  then Path else "diagram.puml"),
               Out_Dir        => To_String (Out_Dir));
      end case;
   end Emit_Classes;

end PlantUML2Code_Formats;
