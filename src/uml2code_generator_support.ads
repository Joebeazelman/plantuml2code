with Ada.Containers.Indefinite_Ordered_Sets;
with Templates_Parser;

package Uml2Code_Generator_Support is
   package String_Sets is new Ada.Containers.Indefinite_Ordered_Sets (String);
   procedure Render_To (Subdir, Template, Output : String; T : Templates_Parser.Translate_Set);
   procedure Render_If_Missing (Subdir, Template, Output : String; T : Templates_Parser.Translate_Set);
   procedure Refuse_Crate_Internal_Output (Out_Dir : String);
end Uml2Code_Generator_Support;
