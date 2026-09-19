with Ada.Environment_Variables;

package body PlantUML2Code_Ansi is

   Mode   : Color_Mode := Auto;
   Active : Boolean := False;

   function Auto_Enabled return Boolean is
   begin
      if Ada.Environment_Variables.Exists ("NO_COLOR") then
         return False;
      end if;
      if Ada.Environment_Variables.Exists ("TERM") then
         declare
            T : constant String :=
              Ada.Environment_Variables.Value ("TERM");
         begin
            return T'Length > 0 and then T /= "dumb";
         end;
      end if;
      return False;
   end Auto_Enabled;

   procedure Set_Mode (M : Color_Mode) is
   begin
      Mode := M;
      case Mode is
         when Always => Active := True;
         when Never  => Active := False;
         when Auto   => Active := Auto_Enabled;
      end case;
   end Set_Mode;

   function Enabled return Boolean is (Active);

   function SGR (Code : String; S : String) return String is
     (if Active then ASCII.ESC & "[" & Code & "m" & S
                              & ASCII.ESC & "[0m"
      else S);

   function Bold    (S : String) return String is (SGR ("1", S));
   function Dim     (S : String) return String is (SGR ("2", S));
   function Red     (S : String) return String is (SGR ("31", S));
   function Green   (S : String) return String is (SGR ("32", S));
   function Yellow  (S : String) return String is (SGR ("33", S));
   function Blue    (S : String) return String is (SGR ("34", S));
   function Magenta (S : String) return String is (SGR ("35", S));
   function Cyan    (S : String) return String is (SGR ("36", S));

end PlantUML2Code_Ansi;
