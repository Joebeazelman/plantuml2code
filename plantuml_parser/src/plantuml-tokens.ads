with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package PlantUML.Tokens is
   pragma Preelaborate;

   type Token_Kind is (Word, Str, Symbol, Arrow, Newline, Eof);

   type Token is record
      Kind : Token_Kind := Eof;
      Text : Unbounded_String;
      Line : Positive := 1;
   end record;

   package Vectors is new Ada.Containers.Vectors (Positive, Token);
   subtype List is Vectors.Vector;

   function Tokenize (Source : String) return List;

   type Cursor (Src : not null access constant List) is private;

   function  Make     (L : aliased in List) return Cursor;
   function  Peek     (C : Cursor) return Token;
   procedure Next     (C : in out Cursor);
   function  At_Eof   (C : Cursor) return Boolean;
   function  Position (C : Cursor) return Natural;
   function  Word_Is  (C : Cursor; S : String) return Boolean;
   function  Sym_Is   (C : Cursor; S : String) return Boolean;

private
   type Cursor (Src : not null access constant List) is record
      I : Natural := 1;
   end record;
end PlantUML.Tokens;
