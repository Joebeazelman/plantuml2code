--  ANSI SGR helpers, backed by AnsiAda.
--
--  Coloring is active when:
--    * --color=always was passed, OR
--    * --color=auto (the default), NO_COLOR is unset, and stdout is
--      a tty.
--  It is never active under --color=never.
--
--  The tty check ensures piped or redirected output never receives
--  escape sequences.

package Uml2Code_Ansi is

   type Color_Mode is (Auto, Always, Never);

   procedure Set_Mode (M : Color_Mode);
   function  Enabled return Boolean;

   function Bold    (S : String) return String;
   function Dim     (S : String) return String;
   function Red     (S : String) return String;
   function Green   (S : String) return String;
   function Yellow  (S : String) return String;
   function Blue    (S : String) return String;
   function Magenta (S : String) return String;
   function Cyan    (S : String) return String;

   --  UML glyphs, used by the help text and text output
   Icon_State_Simple    : constant String := "○";
   Icon_State_Composite : constant String := "▣";
   Icon_Start           : constant String := "●";
   Icon_End             : constant String := "◉";
   Icon_History         : constant String := "↺";
   Icon_Transition      : constant String := "→";
   Icon_Class           : constant String := "▭";
   Icon_Interface       : constant String := "⬚";
   Icon_Enum            : constant String := "⊞";

end Uml2Code_Ansi;
