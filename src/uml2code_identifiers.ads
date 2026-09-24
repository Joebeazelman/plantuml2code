package Uml2Code_Identifiers is
   function Sanitize (S : String; Digit_Prefix : String := "S_") return String;
   function Ada_Case (S : String) return String;
   function Ident (S : String; Digit_Prefix : String := "S_") return String;
end Uml2Code_Identifiers;
