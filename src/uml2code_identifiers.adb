with Ada.Characters.Handling;  use Ada.Characters.Handling;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;

package body Uml2Code_Identifiers is
   function Sanitize (S : String; Digit_Prefix : String := "S_") return String is
      R : Unbounded_String; Last_Was_Underscore : Boolean := False;
   begin
      for C of S loop
         if C in 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' then
            Append (R, C); Last_Was_Underscore := False;
         elsif not Last_Was_Underscore and then Length (R) > 0 then
            Append (R, '_'); Last_Was_Underscore := True;
         end if;
      end loop;
      while Length (R) > 0 and then Element (R, Length (R)) = '_' loop
         Delete (R, Length (R), Length (R));
      end loop;
      if Length (R) = 0 then return "Unnamed";
      elsif Element (R, 1) in '0' .. '9' then return Digit_Prefix & To_String (R);
      else return To_String (R); end if;
   end Sanitize;

   function Ada_Case (S : String) return String is
      R : String (S'Range); At_Start : Boolean := True;
   begin
      for I in S'Range loop
         if S (I) = '_' then R (I) := '_'; At_Start := True;
         elsif At_Start then R (I) := To_Upper (S (I)); At_Start := False;
         else R (I) := To_Lower (S (I)); end if;
      end loop;
      return R;
   end Ada_Case;

   function Ident (S : String; Digit_Prefix : String := "S_") return String
   is (Ada_Case (Sanitize (S, Digit_Prefix)));
end Uml2Code_Identifiers;
