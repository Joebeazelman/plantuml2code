--  Custom filters for JinTP template engine.

with Jintp;
with Ada.Strings.Unbounded;

package Uml2Code_Filters is

   --  Use JinTP's types directly so our functions are type-conformant
   subtype Filter_Function is Jintp.Filter_Function;

   function Sanitize_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Ada_Case_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Ident_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Ada_Ident_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Ada_Type_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Ada_Rel_Type_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Ada.Strings.Unbounded.Unbounded_String;

   --  Stub for backward compatibility with class generator
   procedure Initialize;

   --  Register all custom filters with a JinTP environment
   procedure Register_Filters (Env : in out Jintp.Environment);

end Uml2Code_Filters;
