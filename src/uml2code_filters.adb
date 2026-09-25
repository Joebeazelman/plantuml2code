with Ada.Characters.Handling;
with Ada.Strings.Unbounded;

package body Uml2Code_Filters is

   use Ada.Characters.Handling;
   use Ada.Strings.Unbounded;

   --  Global environment used by Register_Filters (no-arg version)
   Global_Env : Jintp.Environment;

   function Sanitize_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Unbounded_String
   is
      S : constant String := To_String (Arguments (Arguments'First));
      R : Unbounded_String;
      Last_Was_Underscore : Boolean := False;
   begin
      for C of S loop
         if C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' then
            Append (R, C);
            Last_Was_Underscore := False;
         elsif not Last_Was_Underscore and then Length (R) > 0 then
            Append (R, '_');
            Last_Was_Underscore := True;
         end if;
      end loop;

      while Length (R) > 0 and then Element (R, Length (R)) = '_' loop
         Delete (R, Length (R), Length (R));
      end loop;

      if Length (R) = 0 then
         return To_Unbounded_String ("Unnamed");
      elsif Element (R, 1) in '0' .. '9' then
         return To_Unbounded_String ("S_") & R;
      else
         return R;
      end if;
   end Sanitize_Filter;

   function Ada_Case_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Unbounded_String
   is
      S : constant String := To_String (Arguments (Arguments'First));
      R : String (S'Range);
      At_Start : Boolean := True;
   begin
      for I in S'Range loop
         if S (I) = '_' then
            R (I) := '_';
            At_Start := True;
         elsif At_Start then
            R (I) := To_Upper (S (I));
            At_Start := False;
         else
            R (I) := To_Lower (S (I));
         end if;
      end loop;
      return To_Unbounded_String (R);
   end Ada_Case_Filter;

   function Ident_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Unbounded_String
   is
      Sanitized : constant Unbounded_String := Sanitize_Filter (Arguments);
      Args : constant Jintp.Unbounded_String_Array := [Sanitized];
   begin
      return Ada_Case_Filter (Args);
   end Ident_Filter;

   procedure Initialize is
   begin
      Register_Filters (Global_Env);
   end Initialize;

   function Ada_Ident_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Unbounded_String
   is
      --  Same as Ident_Filter but with T_ prefix for types
      Sanitized : constant Unbounded_String := Sanitize_Filter (Arguments);
      Args : constant Jintp.Unbounded_String_Array := [Sanitized];
   begin
      return Ada_Case_Filter (Args);
   end Ada_Ident_Filter;

   function Ada_Type_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Unbounded_String
   is
      S : constant String := To_Lower (To_String (Arguments (Arguments'First)));
   begin
      if S = "string" or else S = "str" then
         return To_Unbounded_String ("Unbounded_String");
      elsif S = "int" or else S = "integer" then
         return To_Unbounded_String ("Integer");
      elsif S = "bool" or else S = "boolean" then
         return To_Unbounded_String ("Boolean");
      elsif S = "float" or else S = "real" then
         return To_Unbounded_String ("Float");
      else
         --  For user-defined types, apply Ada case
         return Ada_Case_Filter (Arguments);
      end if;
   end Ada_Type_Filter;

   function Ada_Rel_Type_Filter
     (Arguments : Jintp.Unbounded_String_Array)
      return Unbounded_String
   is
      --  This filter expects a dictionary with "target" and "kind" fields
      --  For now, just return the target with access prefix
      --  Full implementation would check if target is enum, composition, etc.
      Target : constant String := To_String (Arguments (Arguments'First));
      Ada_Target : constant Unbounded_String := Ada_Case_Filter (Arguments);
   begin
      return To_Unbounded_String ("access ") & Ada_Target;
   end Ada_Rel_Type_Filter;

   procedure Register_Filters (Env : in out Jintp.Environment) is
   begin
      Jintp.Register_Filter (Env, Sanitize_Filter'Access, "sanitize");
      Jintp.Register_Filter (Env, Ada_Case_Filter'Access, "ada_case");
      Jintp.Register_Filter (Env, Ident_Filter'Access, "ident");
      Jintp.Register_Filter (Env, Ada_Ident_Filter'Access, "ada_ident");
      Jintp.Register_Filter (Env, Ada_Type_Filter'Access, "ada_type");
      Jintp.Register_Filter (Env, Ada_Rel_Type_Filter'Access, "ada_rel_type");
   end Register_Filters;

end Uml2Code_Filters;
