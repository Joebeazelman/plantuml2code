--  Ada-specific comment rendering for generated source files.
--
--  This is deliberately kept out of templates: templates receive rendered
--  comment_lines and only decide where those lines are placed.

with Jintp;

package Uml2Code_Ada_Comments is

   --  Convert semantic comment text into Ada comment lines.  Existing line
   --  breaks are preserved and long lines wrap at word boundaries.  A word
   --  (including a URL or identifier) is never split.
   function Comment_Lines
     (Text       : String;
      Wrap_Width : Positive := 78) return Jintp.List;

end Uml2Code_Ada_Comments;
