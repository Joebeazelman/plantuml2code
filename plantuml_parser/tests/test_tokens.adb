with AUnit.Assertions;   use AUnit.Assertions;
with AUnit.Test_Cases;   use AUnit.Test_Cases;

with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

with PlantUML.Tokens;    use PlantUML.Tokens;

package body Test_Tokens is

   procedure Test_Empty (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant List := Tokenize ("");
   begin
      Assert (Natural (L.Length) = 1, "empty input yields only Eof");
      Assert (L (1).Kind = Eof, "first token is Eof");
   end Test_Empty;

   procedure Test_Directive_Is_One_Word (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant List := Tokenize ("@startuml");
   begin
      Assert (L (1).Kind = Word, "@startuml is a Word");
      Assert (To_String (L (1).Text) = "@startuml",
              "text is @startuml");
   end Test_Directive_Is_One_Word;

   procedure Test_Line_Comment (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant List := Tokenize ("' a comment" & ASCII.LF & "x");
   begin
      Assert (L (1).Kind = Newline,
              "comment is dropped, newline kept");
      Assert (L (2).Kind = Word, "next token is x");
   end Test_Line_Comment;

   procedure Test_Quoted_String (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant List := Tokenize ("""hello world""");
   begin
      Assert (L (1).Kind = Str, "quoted string is Str");
      Assert (To_String (L (1).Text) = "hello world",
              "text is the content between quotes");
   end Test_Quoted_String;

   procedure Test_Arrow_Recognised (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant List := Tokenize ("-->");
   begin
      Assert (L (1).Kind = Arrow, "--> is an Arrow");
      Assert (To_String (L (1).Text) = "-->", "text preserved");
   end Test_Arrow_Recognised;

   procedure Test_Composition_Is_Arrow (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant List := Tokenize ("*--");
   begin
      Assert (L (1).Kind = Arrow, "*-- is an Arrow");
   end Test_Composition_Is_Arrow;

   procedure Test_Single_Dash_Is_Symbol (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : constant List := Tokenize ("-");
   begin
      Assert (L (1).Kind = Symbol, "single - is a Symbol");
   end Test_Single_Dash_Is_Symbol;

   procedure Test_Unterminated_String (T : in out Test_Case'Class) is
      pragma Unreferenced (T);
      L : List;
      pragma Unreferenced (L);
   begin
      begin
         L := Tokenize ("""no end quote");
         Assert (False, "expected Parse_Error");
      exception
         when PlantUML.Parse_Error => null;
      end;
   end Test_Unterminated_String;

   overriding
   procedure Register_Tests (T : in out Case_Type) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine (T, Test_Empty'Access, "empty input");
      Register_Routine (T, Test_Directive_Is_One_Word'Access,
                        "directive token");
      Register_Routine (T, Test_Line_Comment'Access, "line comment");
      Register_Routine (T, Test_Quoted_String'Access, "quoted string");
      Register_Routine (T, Test_Arrow_Recognised'Access, "arrow");
      Register_Routine (T, Test_Composition_Is_Arrow'Access,
                        "composition arrow");
      Register_Routine (T, Test_Single_Dash_Is_Symbol'Access,
                        "single dash is symbol");
      Register_Routine (T, Test_Unterminated_String'Access,
                        "unterminated string raises");
   end Register_Tests;

   overriding
   function Name (T : Case_Type) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Tokens");
   end Name;

end Test_Tokens;
