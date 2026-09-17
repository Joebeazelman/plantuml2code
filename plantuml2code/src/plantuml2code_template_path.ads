--  Locates template files at runtime.
--
--  Search order:
--    0. CLI-supplied directory (via Set_Override)
--    1. $PLANTUML2CODE_TEMPLATES
--    2. resources/templates under the executable's parent
--    3. resources/templates under the executable's directory
--    4. resources/templates under the current directory
--
--  The format subdir is tried first; if not found, the "default"
--  subdir is tried as a fallback.

package PlantUML2Code_Template_Path is

   procedure Set_Override (Dir : String);
   procedure Clear_Override;

   function Locate (Subdir : String; File : String) return String;

   Template_Not_Found : exception;

end PlantUML2Code_Template_Path;
