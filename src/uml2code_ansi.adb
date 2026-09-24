with Ada.Environment_Variables;
with Ada.Text_IO;
with Ada.Text_IO.C_Streams;
with Interfaces.C_Streams;
with AnsiAda;

package body Uml2Code_Ansi is

   Mode   : Color_Mode := Auto;
   Active : Boolean := False;

   --  Return True when stdout is a tty. Uses isatty so that piped
   --  output never receives escape codes. NO_COLOR overrides.
   function Auto_Enabled return Boolean is
   begin
      if Ada.Environment_Variables.Exists ("NO_COLOR") then
         return False;
      end if;
      return Interfaces.C_Streams.Isatty
               (Interfaces.C_Streams.FileNo
                  (Ada.Text_IO.C_Streams.C_Stream
                     (Ada.Text_IO.Standard_Output))) /= 0;
   exception
      when others =>
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

   function Style_Wrap (S : String; Sty : AnsiAda.Styles)
                        return String is
     (if Active then AnsiAda.Style_Wrap (S, Sty) else S);

   function Color_Wrap (S : String; Col : AnsiAda.Colors)
                        return String is
     (if Active
      then AnsiAda.Color_Wrap (S, AnsiAda.Foreground (Col))
      else S);

   function Bold    (S : String) return String is
     (Style_Wrap (S, AnsiAda.Bright));
   function Dim     (S : String) return String is
     (Style_Wrap (S, AnsiAda.Dim));
   function Red     (S : String) return String is
     (Color_Wrap (S, AnsiAda.Red));
   function Green   (S : String) return String is
     (Color_Wrap (S, AnsiAda.Green));
   function Yellow  (S : String) return String is
     (Color_Wrap (S, AnsiAda.Yellow));
   function Blue    (S : String) return String is
     (Color_Wrap (S, AnsiAda.Blue));
   function Magenta (S : String) return String is
     (Color_Wrap (S, AnsiAda.Magenta));
   function Cyan    (S : String) return String is
     (Color_Wrap (S, AnsiAda.Cyan));

end Uml2Code_Ansi;
