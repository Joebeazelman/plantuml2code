--  Support utilities for code generators.

with Ada.Containers.Indefinite_Ordered_Sets;
with Jintp;

package Uml2Code_Generator_Support is

   --  Growing set of strings; replaces fixed-size Seen tables.
   package String_Sets is
     new Ada.Containers.Indefinite_Ordered_Sets (String);

   function Locate_Template
     (Subdir   : String;
      Template : String) return String;

   procedure Render_To
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment);

   procedure Render_If_Missing
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment);

   function Safe_Name (S : String) return String;

   procedure Refuse_Crate_Internal_Output (Out_Dir : String);

   procedure Render_To_Dict
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment);

   function Render_Dict
     (Subdir   : String;
      Template : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment) return String;

   procedure Render_If_Missing_Dict
     (Subdir   : String;
      Template : String;
      Output   : String;
      Dict     : Jintp.Dictionary;
      Env      : in out Jintp.Environment);

end Uml2Code_Generator_Support;
