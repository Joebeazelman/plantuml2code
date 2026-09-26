--  Locates template files at runtime.
--
--  Search order:
--    0. CLI-supplied directory (via Set_Override)
--    1. Project config:   ./uml2code.conf
--    2. Home config:      ~/.config/uml2code/config
--    3. $UML2CODE_TEMPLATES
--    4. resources/templates under the current directory
--    5. resources/templates under the executable's parent
--    6. resources/templates under the executable's directory
--
--  Config files use a flat `key = value` format; lines beginning
--  with '#' are comments. `templates_dir` and `ada.comment_wrap` are
--  recognised; other keys are ignored. Malformed lines raise Config_Error.
--
--  The format subdir is tried first; if not found, the "default"
--  subdir is tried as a fallback.

package Uml2Code_Template_Path is

   procedure Set_Override (Dir : String);
   procedure Clear_Override;

   --  Width, including the Ada "-- " prefix, used when rendering generated
   --  comments.  It defaults to 78 and may be set with `ada.comment_wrap`.
   function Comment_Wrap return Positive;

   function Locate (Subdir : String; File : String) return String;

   Template_Not_Found : exception;
   Config_Error       : exception;

   --  Read ./uml2code.conf then ~/.config/uml2code/config, in that
   --  order. The first that yields a templates_dir sets the override.
   --  Does nothing if Set_Override has already been called (CLI -t
   --  wins). Raises Config_Error on a malformed line.
   procedure Load_Config;

   --  Parse a config file's contents. Returns the value of
   --  templates_dir, or "" if absent. Source_Name is used only in
   --  error messages. Visible for testing.
   function Parse_Config (Content     : String;
                          Source_Name : String) return String;

end Uml2Code_Template_Path;
