with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Calendar;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;

with UML.Model;                use UML.Model;

with PlantUML2Code_Utils;      use PlantUML2Code_Utils;
with PlantUML2Code_Ada;
with Templates_Parser;         use Templates_Parser;

package body PlantUML2Code_Ada_Classes is

   --  Templates_Parser.Tag shadows UML.Model.Annotation_Kind's
   --  Tag literal. Nothing here uses the literal.
   subtype Tag is Templates_Parser.Tag;

   --  UML.Model.Element shadows Ada.Strings.Unbounded.Element
   --  (the function). Alias the type so type positions resolve.
   subtype Element is UML.Model.Element;

   --  Declaration ordering: enums, then interfaces, then classes.
   type Layer_Kind is (Enum_Layer, Interface_Layer, Class_Layer);

   function Is_Override (D : UML.Model.Diagram;
                         Idx : Element_Index;
                         Method_Name : String) return Boolean;

   --  =========================================================
   --  Identifier sanitization
   --  =========================================================
   function Sanitize (S : String) return String is
      R : Unbounded_String;
      Last_Underscore : Boolean := False;
   begin
      for C of S loop
         if (C in 'a' .. 'z') or else (C in 'A' .. 'Z')
           or else (C in '0' .. '9')
         then
            Append (R, C);
            Last_Underscore := False;
         else
            if not Last_Underscore and then Length (R) > 0 then
               Append (R, '_');
               Last_Underscore := True;
            end if;
         end if;
      end loop;

      declare
         Tmp : Unbounded_String := R;
      begin
         while Length (Tmp) > 0
           and then Ada.Strings.Unbounded.Element
                      (Tmp, Length (Tmp)) = '_'
         loop
            Delete (Tmp, Length (Tmp), Length (Tmp));
         end loop;

         if Length (Tmp) = 0 then
            return "Unnamed";
         end if;

         if Ada.Strings.Unbounded.Element (Tmp, 1) in '0' .. '9' then
            return "T_" & To_String (Tmp);
         end if;

         return To_String (Tmp);
      end;
   end Sanitize;

   --  Ada identifier casing: each underscore-separated word gets its
   --  first letter upper, the rest lower.
   function Ada_Case (S : String) return String is
      R        : Unbounded_String;
      At_Start : Boolean := True;
   begin
      for C of S loop
         if C = '_' then
            Append (R, C);
            At_Start := True;
         elsif At_Start then
            Append (R, Character'Val
                      (if C in 'a' .. 'z'
                       then Character'Pos (C) - 32
                       else Character'Pos (C)));
            At_Start := False;
         else
            Append (R, Character'Val
                      (if C in 'A' .. 'Z'
                       then Character'Pos (C) + 32
                       else Character'Pos (C)));
         end if;
      end loop;
      return To_String (R);
   end Ada_Case;

   --  Sanitize then Ada-case, for identifier positions.
   function Ident (S : String) return String is
     (Ada_Case (Sanitize (S)));

   --  =========================================================
   --  Type mapping
   --  =========================================================
   function Map_Type (S : String) return String is
      Lower : String (S'Range);
   begin
      if S'Length = 0 then
         return "";
      end if;
      for I in S'Range loop
         Lower (I) :=
           (if S (I) in 'A' .. 'Z'
            then Character'Val (Character'Pos (S (I)) + 32)
            else S (I));
      end loop;
      if Ada.Strings.Fixed.Index (Lower, "string") > 0 then
         return "Unbounded_String";
      elsif Ada.Strings.Fixed.Index (Lower, "bool") > 0 then
         return "Boolean";
      elsif Ada.Strings.Fixed.Index (Lower, "float") > 0
        or else Ada.Strings.Fixed.Index (Lower, "double") > 0
        or else Ada.Strings.Fixed.Index (Lower, "real") > 0
      then
         return "Float";
      elsif Ada.Strings.Fixed.Index (Lower, "void") > 0 then
         return "";
      else
         return "Integer";
      end if;
   end Map_Type;


   --  Title metadata as a comment line.
   function Title_Line_Of (D : UML.Model.Diagram) return String is
   begin
      for M of D.Metadata loop
         if M.Kind = UML.Model.Title and then Length (M.Text) > 0 then
            return "--  " & To_String (M.Text);
         end if;
      end loop;
      return "";
   end Title_Line_Of;

   --  Pack diagram-level notes into a comment block. Each line of each
   --  note is prefixed with "--    ". Empty string when no notes.
   function Notes_Header_Of (D : UML.Model.Diagram) return String is
      R : Unbounded_String;

      procedure Emit_Lines (Txt : String) is
         Start : Natural := Txt'First;
      begin
         if Txt'Length = 0 then
            return;
         end if;
         for I in Txt'Range loop
            if Txt (I) = ASCII.LF then
               Append (R, "--    " & Txt (Start .. I - 1) & ASCII.LF);
               Start := I + 1;
            end if;
         end loop;
         if Start <= Txt'Last then
            Append (R, "--    " & Txt (Start .. Txt'Last) & ASCII.LF);
         end if;
      end Emit_Lines;
   begin
      for N of D.Notes loop
         Emit_Lines (To_String (N.Text));
      end loop;

      --  Trim the trailing newline; the template supplies the final
      --  line break before the closing rule.
      declare
         S : constant String := To_String (R);
      begin
         if S'Length > 0 and then S (S'Last) = ASCII.LF then
            return S (S'First .. S'Last - 1);
         end if;
         return S;
      end;
   end Notes_Header_Of;

   function Dummy_Value (Typ : String) return String is
   begin
      if Typ = "Unbounded_String" then
         return "Null_Unbounded_String";
      elsif Typ = "Boolean" then
         return "False";
      elsif Typ = "Float" then
         return "0.0";
      else
         return "0";
      end if;
   end Dummy_Value;

   --  =========================================================
   --  Helpers
   --  =========================================================
   function Id_Of (D : UML.Model.Diagram; Idx : Element_Index)
                   return String is
     (To_String (D.Elements (Positive (Idx)).Id));

   function Root_Package_Name (D : UML.Model.Diagram) return String is
     (if Length (D.Id) > 0 then Sanitize (To_String (D.Id)) else "Model");

   function Package_Name_Of (D : UML.Model.Diagram;
                             Pkg : Element_Index) return String is
   begin
      if Pkg = 0 then
         return Root_Package_Name (D);
      else
         return Sanitize (Id_Of (D, Pkg));
      end if;
   end Package_Name_Of;

   --  Elements contained directly by package Pkg (or root if Pkg = 0),
   --  excluding the package element itself.
   function Members_Of (D : UML.Model.Diagram; Pkg : Element_Index)
                        return Element_Index_Vectors.Vector
   is
      R : Element_Index_Vectors.Vector;
   begin
      if Pkg = 0 then
         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            declare
               E : constant Element := D.Elements (I);
            begin
               if E.Parent = 0 and then E.Kind /= Package_Kind then
                  R.Append (Element_Index (I));
               end if;
            end;
         end loop;
      else
         for C of D.Elements (Positive (Pkg)).Children loop
            if D.Elements (Positive (C)).Kind /= Package_Kind then
               R.Append (C);
            end if;
         end loop;
      end if;
      return R;
   end Members_Of;

   --  Return the nearest ancestor of a package-like kind, or 0 if
   --  this element is at the top level.
   function Enclosing_Package (D : UML.Model.Diagram; Idx : Element_Index)
                               return Element_Index is
   begin
      for I in D.Elements.First_Index .. D.Elements.Last_Index loop
         for C of D.Elements (I).Children loop
            if C = Idx and then D.Elements (I).Kind = Package_Kind then
               return Element_Index (I);
            end if;
         end loop;
      end loop;
      return 0;
   end Enclosing_Package;

   --  Whether the class has any parent relations.
   --  First inheritance parent of a class, or 0.
   function First_Parent (D : UML.Model.Diagram; Idx : Element_Index)
                          return Element_Index is
   begin
      for R of D.Relations loop
         if R.To = Idx and then R.Kind = UML.Model.Inheritance then
            return R.From;
         end if;
      end loop;
      return 0;
   end First_Parent;

   --  Interface parents (inheritance-to-interface + realization).
   function Interfaces_Of (D : UML.Model.Diagram; Idx : Element_Index)
                           return Element_Index_Vectors.Vector
   is
      R : Element_Index_Vectors.Vector;
   begin
      for Rel of D.Relations loop
         if Rel.To = Idx
           and then (Rel.Kind = UML.Model.Realization
                     or else (Rel.Kind = UML.Model.Inheritance
                              and then
                                D.Elements (Positive (Rel.From)).Kind
                                  = Interface_Kind))
         then
            R.Append (Rel.From);
         end if;
      end loop;
      return R;
   end Interfaces_Of;

   --  Fields for a class: attributes plus association-derived fields.
   function Field_Count (D : UML.Model.Diagram; Idx : Element_Index)
                         return Natural is
      N : Natural := 0;
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = UML.Model.Attribute then
            N := N + 1;
         end if;
      end loop;
      for Rel of D.Relations loop
         if Rel.From = Idx
           and then Rel.Kind in UML.Model.Composition
                              | UML.Model.Aggregation
                              | UML.Model.Association
           and then Rel.To /= Idx
         then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Field_Count;

   --  Whether a member is declared abstract in the diagram.
   function Member_Is_Abstract (M : Member) return Boolean is
     (M.Is_Abstract);

   --  Concrete (non-abstract) methods on an element.
   --  Does this type have any inherited abstract methods that a
   --  concrete class must override? (returns count)
   --  =========================================================
   --  WITH clause construction
   --  =========================================================
   function With_Clauses_For (D : UML.Model.Diagram;
                              Pkg : Element_Index;
                              Self_Pkg_Name : String;
                              Needs_Unbounded : out Boolean)
                              return String
   is
      Uses : array (1 .. 32) of Unbounded_String;
      N    : Natural := 0;

      procedure Add (Pkg_Name : String) is
      begin
         if Pkg_Name = Self_Pkg_Name then
            return;
         end if;
         for I in 1 .. N loop
            if To_String (Uses (I)) = Pkg_Name then
               return;
            end if;
         end loop;
         N := N + 1;
         Uses (N) := To_Unbounded_String (Pkg_Name);
      end Add;

      Members : constant Element_Index_Vectors.Vector :=
        Members_Of (D, Pkg);

      Result : Unbounded_String;
   begin
      Needs_Unbounded := False;

      for Idx of Members loop
         --  Parents and interfaces of each classifier.
         for R of D.Relations loop
            if R.To = Idx
              and then R.Kind in UML.Model.Inheritance
                                  | UML.Model.Realization
            then
               declare
                  Target_Pkg : constant Element_Index :=
                    Enclosing_Package (D, R.From);
                  Target_Pkg_Name : constant String :=
                    Package_Name_Of (D, Target_Pkg);
               begin
                  if Target_Pkg_Name /= Self_Pkg_Name then
                     Add (Target_Pkg_Name);
                  end if;
               end;
            end if;
         end loop;

         --  Association targets.
         for R of D.Relations loop
            if R.From = Idx
              and then R.Kind in UML.Model.Composition
                                  | UML.Model.Aggregation
                                  | UML.Model.Association
              and then R.To /= Idx
            then
               declare
                  Target_Pkg : constant Element_Index :=
                    Enclosing_Package (D, R.To);
                  Target_Pkg_Name : constant String :=
                    Package_Name_Of (D, Target_Pkg);
               begin
                  if Target_Pkg_Name /= Self_Pkg_Name then
                     Add (Target_Pkg_Name);
                  end if;
               end;
            end if;
         end loop;

         --  Attribute / method types.
         for M of D.Elements (Positive (Idx)).Members loop
            if Map_Type (To_String (M.Type_Name)) = "Unbounded_String" then
               Needs_Unbounded := True;
            end if;
         end loop;
      end loop;

      for I in 1 .. N loop
         Append (Result, "with " & To_String (Uses (I))
                 & ";  use " & To_String (Uses (I)) & ";" & ASCII.LF);
      end loop;

      if Needs_Unbounded then
         Append (Result,
                 "with Ada.Strings.Unbounded;"
                 & "  use Ada.Strings.Unbounded;" & ASCII.LF);
      end if;

      if Length (Result) > 0 then
         Append (Result, ASCII.LF);
      end if;

      return To_String (Result);
   end With_Clauses_For;

   --  =========================================================
   --  Type declaration blocks
   --  =========================================================
   function Enum_Decl (D : UML.Model.Diagram; Idx : Element_Index)
                       return String
   is
      Name     : constant String := Ident (Id_Of (D, Idx));
      Literals : Tag;
      T        : Translate_Set;
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = UML.Model.Enum_Literal then
            Literals := Literals & Ident (To_String (M.Id));
         end if;
      end loop;
      Insert (T, Assoc ("NAME", Name));
      Insert (T, Assoc ("LITERALS", Literals));
      declare
         S : constant String :=
           Render_Template ("ada/class", "enum_decl.tmplt", T);
      begin
         if S'Length > 0 and then S (S'Last) = ASCII.LF then
            return S (S'First .. S'Last - 1);
         end if;
         return S;
      end;
   end Enum_Decl;

   function Interface_Decl (D : UML.Model.Diagram; Idx : Element_Index)
                            return String
   is
      Name : constant String := Ident (Id_Of (D, Idx));
      E    : constant Element := D.Elements (Positive (Idx));

      T_Head : Translate_Set;
      T_Meth : Translate_Set;
      Override_Flags : Tag;
      Method_Decls   : Tag;
      Has_Methods : Boolean := False;
   begin
      for M of E.Members loop
         if M.Kind = UML.Model.Method then
            declare
               M_Name : constant String := Ident (To_String (M.Id));
               Ret    : constant String :=
                 Map_Type (To_String (M.Type_Name));
               Decl   : Unbounded_String := Null_Unbounded_String;
            begin
               if Ret'Length = 0 then
                  Append (Decl, "procedure " & M_Name
                          & " (Self : in out " & Name & ")");
               else
                  Append (Decl, "function " & M_Name
                          & " (Self : in out " & Name & ") return " & Ret);
               end if;
               Append (Decl, " is abstract;");
               Override_Flags := Override_Flags & False;
               Method_Decls := Method_Decls & To_String (Decl);
               Has_Methods := True;
            end;
         end if;
      end loop;

      Insert (T_Head, Assoc ("NAME", Name));
      declare
         Head : Unbounded_String :=
           To_Unbounded_String
             (Render_Template ("ada/class", "interface_head.tmplt", T_Head));
      begin
         while Length (Head) > 0
           and then Ada.Strings.Unbounded.Element
                      (Head, Length (Head)) = ASCII.LF
         loop
            Delete (Head, Length (Head), Length (Head));
         end loop;
         if Has_Methods then
            Append (Head, ASCII.LF & ASCII.LF);
            Insert (T_Meth, Assoc ("METHOD_OVERRIDING", Override_Flags));
            Insert (T_Meth, Assoc ("METHOD_DECL", Method_Decls));
            Append (Head,
                    Render_Template ("ada/class", "methods.tmplt", T_Meth));
         end if;
         declare
            S : constant String := To_String (Head);
         begin
            if S'Length > 0 and then S (S'Last) = ASCII.LF then
               return S (S'First .. S'Last - 1);
            end if;
            return S;
         end;
      end;
   end Interface_Decl;

   function Class_Decl (D : UML.Model.Diagram; Idx : Element_Index)
                        return String
   is
      Name        : constant String := Ident (Id_Of (D, Idx));
      E           : constant Element := D.Elements (Positive (Idx));
      Is_Abstract : constant Boolean := E.Kind = Abstract_Class;

      Parent_Idx : constant Element_Index := First_Parent (D, Idx);
      Interfaces : constant Element_Index_Vectors.Vector :=
        Interfaces_Of (D, Idx);
      Has_Parent : constant Boolean := Parent_Idx /= 0;

      T_Head : Translate_Set;
      T_Meth : Translate_Set;
      Field_Names : Tag;
      Field_Types : Tag;
      Override_Flags : Tag;
      Method_Decls   : Tag;
      Has_Methods : Boolean := False;
      Has_Fields  : Boolean := False;

      Derivation : Unbounded_String;
      First      : Boolean := True;
   begin
      --  Build DERIVATION string.
      if not Has_Parent and then Interfaces.Is_Empty then
         Append (Derivation, "tagged");
      else
         if Has_Parent then
            Append (Derivation, "new " & Ident (Id_Of (D, Parent_Idx)));
            First := False;
         end if;
         for I of Interfaces loop
            if First then
               Append (Derivation, "new " & Ident (Id_Of (D, I)));
               First := False;
            else
               Append (Derivation, " and " & Ident (Id_Of (D, I)));
            end if;
         end loop;
         Append (Derivation, " with");
      end if;

      --  Fields: attributes then association-derived.
      for M of E.Members loop
         if M.Kind = UML.Model.Attribute then
            Field_Names := Field_Names & Ident (To_String (M.Id));
            Field_Types := Field_Types
              & Map_Type (To_String (M.Type_Name));
            Has_Fields := True;
         end if;
      end loop;
      for Rel of D.Relations loop
         if Rel.From = Idx
           and then Rel.Kind in UML.Model.Composition
                               | UML.Model.Aggregation
                               | UML.Model.Association
           and then Rel.To /= Idx
         then
            declare
               Target_Name : constant String :=
                 Ident (Id_Of (D, Rel.To));
               Target_Kind : constant Element_Kind :=
                 D.Elements (Positive (Rel.To)).Kind;
            begin
               Field_Names := Field_Names & Target_Name;
               Has_Fields := True;
               if Target_Kind = Enumeration then
                  Field_Types := Field_Types & Target_Name;
               else
                  Field_Types := Field_Types
                    & ("access " & Target_Name & "'Class");
               end if;
            end;
         end if;
      end loop;

      --  Methods.
      for M of E.Members loop
         if M.Kind = UML.Model.Method then
            declare
               M_Name : constant String := Ident (To_String (M.Id));
               Ret    : constant String :=
                 Map_Type (To_String (M.Type_Name));
               Is_Abs : constant Boolean := Member_Is_Abstract (M);
               Decl   : Unbounded_String := Null_Unbounded_String;
            begin
               if Ret'Length = 0 then
                  Append (Decl, "procedure " & M_Name
                          & " (Self : in out " & Name & ")");
               else
                  Append (Decl, "function " & M_Name
                          & " (Self : in out " & Name & ") return " & Ret);
               end if;
               if Is_Abs then
                  Append (Decl, " is abstract;");
               else
                  Append (Decl, ";");
               end if;
               Override_Flags := Override_Flags
                 & Is_Override (D, Idx, To_String (M.Id));
               Method_Decls := Method_Decls & To_String (Decl);
               Has_Methods := True;
            end;
         end if;
      end loop;

      Insert (T_Head, Assoc ("NAME", Name));
      Insert (T_Head, Assoc ("ABSTRACT",
                             (if Is_Abstract then " abstract" else "")));
      Insert (T_Head, Assoc ("DERIVATION", To_String (Derivation)));

      declare
         Head : Unbounded_String;
      begin
         if not Has_Fields then
            Head := To_Unbounded_String
              (Render_Template
                 ("ada/class", "class_head_empty.tmplt", T_Head));
         else
            Insert (T_Head, Assoc ("FIELD_NAME", Field_Names));
            Insert (T_Head, Assoc ("FIELD_TYPE", Field_Types));
            Head := To_Unbounded_String
              (Render_Template
                 ("ada/class", "class_head_fields.tmplt", T_Head));
         end if;

         --  Normalize: strip any trailing newline that the head
         --  template produced.
         while Length (Head) > 0
           and then Ada.Strings.Unbounded.Element
                      (Head, Length (Head)) = ASCII.LF
         loop
            Delete (Head, Length (Head), Length (Head));
         end loop;

         if Has_Methods then
            Append (Head, ASCII.LF & ASCII.LF);
            Insert (T_Meth, Assoc ("METHOD_OVERRIDING", Override_Flags));
            Insert (T_Meth, Assoc ("METHOD_DECL", Method_Decls));
            Append (Head,
                    Render_Template ("ada/class", "methods.tmplt", T_Meth));
         end if;

         --  Strip the trailing newline; the package-level template
         --  supplies the blank line between declarations.
         declare
            S : constant String := To_String (Head);
         begin
            if S'Length > 0 and then S (S'Last) = ASCII.LF then
               return S (S'First .. S'Last - 1);
            end if;
            return S;
         end;
      end;
   end Class_Decl;

   --  The "declares Method_Name on type Idx" query used inside
   --  Class_Decl above, promoted to a proper function for the
   --  "overriding" decision.
   function Is_Override (D : UML.Model.Diagram;
                         Idx : Element_Index;
                         Method_Name : String) return Boolean
   is
   begin
      for Rel of D.Relations loop
         if Rel.To = Idx
           and then Rel.Kind in UML.Model.Inheritance | UML.Model.Realization
         then
            for M of D.Elements (Positive (Rel.From)).Members loop
               if M.Kind = UML.Model.Method
                 and then To_String (M.Id) = Method_Name
               then
                  return True;
               end if;
            end loop;
         end if;
      end loop;
      return False;
   end Is_Override;

   --  =========================================================
   --  Body / Operations blocks
   --  =========================================================
   function Method_Body_Block (D : UML.Model.Diagram;
                               Type_Idx : Element_Index;
                               M : Member) return String
   is
      Type_Name : constant String := Sanitize (Id_Of (D, Type_Idx));
      M_Name    : constant String := Sanitize (To_String (M.Id));
      Ret       : constant String := Map_Type (To_String (M.Type_Name));
      R         : Unbounded_String;
   begin
      if Is_Override (D, Type_Idx, To_String (M.Id)) then
         Append (R, "overriding" & ASCII.LF);
      end if;
      if Ret'Length = 0 then
         Append (R, "procedure " & M_Name
                 & " (Self : in out " & Type_Name & ") is" & ASCII.LF
                 & "begin" & ASCII.LF
                 & "   Operations." & M_Name & " (Self);" & ASCII.LF
                 & "end " & M_Name & ";");
      else
         Append (R, "function " & M_Name
                 & " (Self : in out " & Type_Name & ") return "
                 & Ret & " is" & ASCII.LF
                 & "begin" & ASCII.LF
                 & "   return Operations." & M_Name & " (Self);"
                 & ASCII.LF
                 & "end " & M_Name & ";");
      end if;
      return To_String (R);
   end Method_Body_Block;

   function Op_Decl_Block (Type_Name : String; M : Member) return String is
      M_Name : constant String := Sanitize (To_String (M.Id));
      Ret    : constant String := Map_Type (To_String (M.Type_Name));
   begin
      if Ret'Length = 0 then
         return "procedure " & M_Name
           & " (Self : in out " & Type_Name & ");";
      else
         return "function " & M_Name
           & " (Self : in out " & Type_Name & ") return " & Ret & ";";
      end if;
   end Op_Decl_Block;

   function Op_Body_Block (Type_Name : String; M : Member) return String is
      M_Name : constant String := Ident (To_String (M.Id));
      Ret    : constant String := Map_Type (To_String (M.Type_Name));
      R      : Unbounded_String;
   begin
      if Ret'Length = 0 then
         Append (R, "procedure " & M_Name
                 & " (Self : in out " & Type_Name & ") is" & ASCII.LF
                 & "begin" & ASCII.LF
                 & "   null;" & ASCII.LF
                 & "end " & M_Name & ";");
      else
         Append (R, "function " & M_Name
                 & " (Self : in out " & Type_Name & ") return "
                 & Ret & " is" & ASCII.LF
                 & "begin" & ASCII.LF
                 & "   raise Program_Error with "
                 & ASCII.Quotation
                 & Type_Name & "." & M_Name & " not implemented"
                 & ASCII.Quotation & ";" & ASCII.LF
                 & "   return " & Dummy_Value (Ret) & ";" & ASCII.LF
                 & "end " & M_Name & ";");
      end if;
      return To_String (R);
   end Op_Body_Block;

   --  =========================================================
   --  File rendering
   --  =========================================================
   procedure Render_To
     (Template : String; Output : String; T : Translate_Set)
   is
      Content : constant String :=
        Render_Template ("ada/class", Template, T);
      F : File_Type;
   begin
      Create (F, Out_File, Output);
      Put (F, Content);
      Close (F);
      Put_Line ("wrote " & Output);
   end Render_To;

   procedure Render_If_Missing
     (Template : String; Output : String; T : Translate_Set)
   is
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
      else
         Render_To (Template, Output, T);
      end if;
   end Render_If_Missing;

   procedure Emit_Driver (D : UML.Model.Diagram;
                          Model_Name : String;
                          Tests_Dir : String)
   is
      Withs  : Unbounded_String;
      Decls  : Unbounded_String;
      Seen   : array (1 .. 64) of Unbounded_String;
      N_Seen : Natural := 0;
      Path   : constant String :=
        Ada.Directories.Compose (Tests_Dir, "driver.adb");

      function Already_With (Pkg_Name : String) return Boolean is
      begin
         for I in 1 .. N_Seen loop
            if To_String (Seen (I)) = Pkg_Name then
               return True;
            end if;
         end loop;
         return False;
      end Already_With;

      procedure Add_Type (Pkg_Name : String; Type_Name : String) is
         Q : constant String := Pkg_Name & "." & Type_Name;
         V : constant String := "X_" & Type_Name;
      begin
         if not Already_With (Pkg_Name) then
            N_Seen := N_Seen + 1;
            Seen (N_Seen) := To_Unbounded_String (Pkg_Name);
            Append (Withs, "with " & Pkg_Name & ";" & ASCII.LF);
         end if;
         Append (Decls,
                 "   " & V & " : " & Q & ";" & ASCII.LF
                 & "   pragma Unreferenced (" & V & ");" & ASCII.LF);
      end Add_Type;
   begin
      for I in D.Elements.First_Index .. D.Elements.Last_Index loop
         declare
            E : constant Element := D.Elements (I);
         begin
            if E.Kind = Class then
               declare
                  Pkg : constant Element_Index := E.Parent;
                  Pkg_Name : constant String :=
                    (if Pkg = 0
                     then Root_Package_Name (D)
                     else Ident (Id_Of (D, Pkg)));
               begin
                  Add_Type (Pkg_Name, Ident (To_String (E.Id)));
               end;
            end if;
         end;
      end loop;

      declare
         F : File_Type;
      begin
         Create (F, Out_File, Path);
         Put (F, "--  Generated driver. Compile-proof only." & ASCII.LF);
         Put (F, ASCII.LF);
         Put (F, "with Ada.Text_IO;  use Ada.Text_IO;" & ASCII.LF);
         Put (F, To_String (Withs));
         Put (F, ASCII.LF);
         Put (F, "procedure Driver is" & ASCII.LF);
         Put (F, To_String (Decls));
         Put (F, "begin" & ASCII.LF);
         Put (F, "   Put_Line (" & ASCII.Quotation
              & Model_Name & ASCII.Quotation & ");" & ASCII.LF);
         Put (F, "end Driver;" & ASCII.LF);
         Close (F);
         Put_Line ("wrote " & Path);
      end;
   end Emit_Driver;

   --  =========================================================
   --  Emit one package (spec + optional body + operations)
   --  =========================================================
   procedure Emit_Package (D : UML.Model.Diagram;
                           Pkg : Element_Index;
                           Source_Diagram : String;
                           Date_Str : String;
                           Src_Dir : String)
   is
      Pkg_Name : constant String := Package_Name_Of (D, Pkg);
      Members  : constant Element_Index_Vectors.Vector :=
        Members_Of (D, Pkg);

      T_Spec   : Translate_Set;
      T_Body   : Translate_Set;
      T_Op_Ads : Translate_Set;
      T_Op_Adb : Translate_Set;

      Decl_Blocks : Tag;

      Method_Bodies : Tag;
      Op_Decls      : Tag;
      Op_Bodies     : Tag;

      Has_Any_Method : Boolean := False;
      Needs_Unbounded : Boolean;

      File_Name : constant String :=
        Ada.Characters.Handling.To_Lower (Pkg_Name);
      Ads_Path : constant String :=
        Ada.Directories.Compose (Src_Dir, File_Name & ".ads");
      Adb_Path : constant String :=
        Ada.Directories.Compose (Src_Dir, File_Name & ".adb");
      Op_Ads   : constant String :=
        Ada.Directories.Compose (Src_Dir, File_Name & "-operations.ads");
      Op_Adb   : constant String :=
        Ada.Directories.Compose (Src_Dir, File_Name & "-operations.adb");

      With_Str : constant String :=
        With_Clauses_For (D, Pkg, Pkg_Name, Needs_Unbounded);
   begin
      --  Accumulate declaration blocks in three passes so enums come
      --  first, then interfaces, then classes. Each block is a full
      --  multi-line type declaration.
      for Layer in Layer_Kind loop
         for Idx of Members loop
            declare
               E : constant Element := D.Elements (Positive (Idx));
            begin
               case Layer is
                  when Enum_Layer =>
                     if E.Kind = Enumeration then
                        Decl_Blocks := Decl_Blocks & Enum_Decl (D, Idx);
                     end if;
                  when Interface_Layer =>
                     if E.Kind = Interface_Kind then
                        Decl_Blocks := Decl_Blocks & Interface_Decl (D, Idx);
                     end if;
                  when Class_Layer =>
                     if E.Kind in Class | Abstract_Class then
                        Decl_Blocks := Decl_Blocks & Class_Decl (D, Idx);
                        for M of E.Members loop
                           if M.Kind = UML.Model.Method
                             and then not Member_Is_Abstract (M)
                           then
                              Has_Any_Method := True;
                              Method_Bodies :=
                                Method_Bodies & Method_Body_Block (D, Idx, M);
                              Op_Decls := Op_Decls
                                & Op_Decl_Block
                                    (Sanitize (Id_Of (D, Idx)), M);
                              Op_Bodies := Op_Bodies
                                & Op_Body_Block
                                    (Sanitize (Id_Of (D, Idx)), M);
                           end if;
                        end loop;
                     end if;
               end case;
            end;
         end loop;
      end loop;

      --  Spec
      Insert (T_Spec, Assoc ("PACKAGE_NAME", Pkg_Name));
      Insert (T_Spec, Assoc ("SOURCE_DIAGRAM", Source_Diagram));
      Insert (T_Spec, Assoc ("GENERATION_DATE", Date_Str));
      Insert (T_Spec, Assoc ("HAS_TITLE",
                             Pkg = 0 and then Title_Line_Of (D)'Length > 0));
      Insert (T_Spec, Assoc ("TITLE_LINE",
                             (if Pkg = 0 then Title_Line_Of (D) else "")));
      Insert (T_Spec, Assoc ("HAS_NOTES",
                             Pkg = 0 and then Notes_Header_Of (D)'Length > 0));
      Insert (T_Spec, Assoc ("NOTES_HEADER",
                             (if Pkg = 0 then Notes_Header_Of (D) else "")));
      Insert (T_Spec, Assoc ("WITH_CLAUSES", With_Str));
      Insert (T_Spec, Assoc ("DECL_BLOCK", Decl_Blocks));
      Render_To ("class.ads.tmplt", Ads_Path, T_Spec);

      if Has_Any_Method then
         --  Body
         Insert (T_Body, Assoc ("PACKAGE_NAME", Pkg_Name));
         Insert (T_Body, Assoc ("SOURCE_DIAGRAM", Source_Diagram));
         Insert (T_Body, Assoc ("GENERATION_DATE", Date_Str));
         Insert (T_Body, Assoc ("WITH_CLAUSES",
                   "with " & Pkg_Name & ".Operations;" & ASCII.LF
                   & ASCII.LF));
         Insert (T_Body, Assoc ("METHOD_BODY", Method_Bodies));
         Render_To ("class.adb.tmplt", Adb_Path, T_Body);

         --  Operations spec
         declare
            --  with + use the parent so unqualified type names in
            --  signatures resolve. GNAT flags the `with` as an
            --  unnecessary-ancestor warning; suppress it and keep
            --  the import for name resolution.
            Op_With : constant String :=
              "with " & Pkg_Name & ";  use " & Pkg_Name & ";"
              & ASCII.LF & ASCII.LF;
         begin
            Insert (T_Op_Ads, Assoc ("PACKAGE_NAME", Pkg_Name));
            Insert (T_Op_Ads, Assoc ("WITH_CLAUSES", Op_With));
            Insert (T_Op_Ads, Assoc ("OP_DECL", Op_Decls));
            Render_If_Missing ("class_operations.ads.tmplt",
                               Op_Ads, T_Op_Ads);

            Insert (T_Op_Adb, Assoc ("PACKAGE_NAME", Pkg_Name));
            Insert (T_Op_Adb, Assoc ("OP_BODY", Op_Bodies));
            Render_If_Missing ("class_operations.adb.tmplt",
                               Op_Adb, T_Op_Adb);
         end;
      end if;
   end Emit_Package;

   --  =========================================================
   --  Entry point
   --  =========================================================

   --  =========================================================
   --  Validation
   --  =========================================================
   --  Structural checks run before any output is emitted. All
   --  problems are reported to Standard_Error; if any were found
   --  the caller raises Validation_Error.

   procedure Validate (D : UML.Model.Diagram) is
      Errors : Natural := 0;

      procedure Report (Msg : String) is
      begin
         Put_Line (Standard_Error,
                   "plantuml2code: error: " & Msg);
         Errors := Errors + 1;
      end Report;

      --  Ada 2022 reserved words. Kept alphabetical for review.
      Reserved : constant array (Positive range <>) of Unbounded_String
        := [To_Unbounded_String ("abort"),
            To_Unbounded_String ("abs"),
            To_Unbounded_String ("abstract"),
            To_Unbounded_String ("accept"),
            To_Unbounded_String ("access"),
            To_Unbounded_String ("aliased"),
            To_Unbounded_String ("all"),
            To_Unbounded_String ("and"),
            To_Unbounded_String ("array"),
            To_Unbounded_String ("at"),
            To_Unbounded_String ("begin"),
            To_Unbounded_String ("body"),
            To_Unbounded_String ("case"),
            To_Unbounded_String ("constant"),
            To_Unbounded_String ("declare"),
            To_Unbounded_String ("delay"),
            To_Unbounded_String ("delta"),
            To_Unbounded_String ("digits"),
            To_Unbounded_String ("do"),
            To_Unbounded_String ("else"),
            To_Unbounded_String ("elsif"),
            To_Unbounded_String ("end"),
            To_Unbounded_String ("entry"),
            To_Unbounded_String ("exception"),
            To_Unbounded_String ("exit"),
            To_Unbounded_String ("for"),
            To_Unbounded_String ("function"),
            To_Unbounded_String ("generic"),
            To_Unbounded_String ("goto"),
            To_Unbounded_String ("if"),
            To_Unbounded_String ("in"),
            To_Unbounded_String ("interface"),
            To_Unbounded_String ("is"),
            To_Unbounded_String ("limited"),
            To_Unbounded_String ("loop"),
            To_Unbounded_String ("mod"),
            To_Unbounded_String ("new"),
            To_Unbounded_String ("not"),
            To_Unbounded_String ("null"),
            To_Unbounded_String ("of"),
            To_Unbounded_String ("or"),
            To_Unbounded_String ("others"),
            To_Unbounded_String ("out"),
            To_Unbounded_String ("overriding"),
            To_Unbounded_String ("package"),
            To_Unbounded_String ("parallel"),
            To_Unbounded_String ("pragma"),
            To_Unbounded_String ("private"),
            To_Unbounded_String ("procedure"),
            To_Unbounded_String ("protected"),
            To_Unbounded_String ("raise"),
            To_Unbounded_String ("range"),
            To_Unbounded_String ("record"),
            To_Unbounded_String ("rem"),
            To_Unbounded_String ("renames"),
            To_Unbounded_String ("requeue"),
            To_Unbounded_String ("return"),
            To_Unbounded_String ("reverse"),
            To_Unbounded_String ("select"),
            To_Unbounded_String ("separate"),
            To_Unbounded_String ("some"),
            To_Unbounded_String ("subtype"),
            To_Unbounded_String ("synchronized"),
            To_Unbounded_String ("tagged"),
            To_Unbounded_String ("task"),
            To_Unbounded_String ("terminate"),
            To_Unbounded_String ("then"),
            To_Unbounded_String ("type"),
            To_Unbounded_String ("until"),
            To_Unbounded_String ("use"),
            To_Unbounded_String ("when"),
            To_Unbounded_String ("while"),
            To_Unbounded_String ("with"),
            To_Unbounded_String ("xor")];

      function Is_Reserved (S : String) return Boolean is
         L : constant String :=
           Ada.Characters.Handling.To_Lower (S);
      begin
         for W of Reserved loop
            if To_String (W) = L then
               return True;
            end if;
         end loop;
         return False;
      end Is_Reserved;

      --  For each element: reserved-word check
      procedure Check_Names is
      begin
         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            declare
               E    : constant Element := D.Elements (I);
               Name : constant String := Ident (To_String (E.Id));
            begin
               if E.Kind /= Package_Kind and then Is_Reserved (Name) then
                  Report ("classifier name '" & To_String (E.Id)
                          & "' is an Ada reserved word"
                          & " (rename it in the diagram)");
               end if;
            end;
         end loop;
      end Check_Names;

      --  Realization (..|>) target must be an interface.
      procedure Check_Realizations is
      begin
         for R of D.Relations loop
            if R.Kind = UML.Model.Realization
              and then D.Elements (Positive (R.From)).Kind
                         /= Interface_Kind
            then
               Report ("realization target '"
                       & To_String (D.Elements (Positive (R.From)).Id)
                       & "' (of '"
                       & To_String (D.Elements (Positive (R.To)).Id)
                       & "') is not an interface");
            end if;
         end loop;
      end Check_Realizations;

      --  An interface may only inherit from other interfaces.
      procedure Check_Interface_Parents is
      begin
         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            if D.Elements (I).Kind = Interface_Kind then
               for R of D.Relations loop
                  if R.To = Element_Index (I)
                    and then R.Kind = UML.Model.Inheritance
                    and then D.Elements (Positive (R.From)).Kind
                               /= Interface_Kind
                  then
                     Report ("interface '"
                             & To_String (D.Elements (I).Id)
                             & "' inherits from '"
                             & To_String (D.Elements (Positive (R.From)).Id)
                             & "', which is not an interface");
                  end if;
               end loop;
            end if;
         end loop;
      end Check_Interface_Parents;

      --  A concrete class may have at most one class parent.
      procedure Check_Multiple_Parents is
      begin
         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            if D.Elements (I).Kind in Class | Abstract_Class then
               declare
                  Count : Natural := 0;
                  Names : Unbounded_String;
               begin
                  for R of D.Relations loop
                     if R.To = Element_Index (I)
                       and then R.Kind = UML.Model.Inheritance
                       and then D.Elements (Positive (R.From)).Kind
                                  in Class | Abstract_Class
                     then
                        Count := Count + 1;
                        if Length (Names) > 0 then
                           Append (Names, ", ");
                        end if;
                        Append (Names,
                                To_String
                                  (D.Elements (Positive (R.From)).Id));
                     end if;
                  end loop;
                  if Count > 1 then
                     Report ("class '"
                             & To_String (D.Elements (I).Id)
                             & "' has multiple class parents: "
                             & To_String (Names));
                  end if;
               end;
            end if;
         end loop;
      end Check_Multiple_Parents;

      --  Inheritance cycle detection: DFS on the inheritance graph.

      function Has_Cycle (Start, Cur : Element_Index) return Boolean is
      begin
         for R of D.Relations loop
            if R.To = Cur and then R.Kind = UML.Model.Inheritance then
               if R.From = Start then
                  Report ("inheritance cycle involving '"
                          & To_String (D.Elements (Positive (Start)).Id)
                          & "' and '"
                          & To_String (D.Elements (Positive (Cur)).Id)
                          & "'");
                  return True;
               elsif Has_Cycle (Start, R.From) then
                  return True;
               end if;
            end if;
         end loop;
         return False;
      end Has_Cycle;

      procedure Check_Cycles is
      begin
         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            if D.Elements (I).Kind in Class | Abstract_Class
                                      | Interface_Kind
            then
               --  Limit recursion: only walk down; if we return to
               --  our start, that's a cycle. Small diagrams only.
               if Has_Cycle (Element_Index (I), Element_Index (I)) then
                  null;  --  Error already reported.
               end if;
            end if;
         end loop;
      end Check_Cycles;

      --  Concrete class must implement every inherited abstract method.
      procedure Check_Abstract_Impls is
      begin
         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            if D.Elements (I).Kind = Class then
               declare
                  This : constant Element := D.Elements (I);

                  function Declares (Method_Name : String) return Boolean is
                  begin
                     for M of This.Members loop
                        if M.Kind = UML.Model.Method
                          and then To_String (M.Id) = Method_Name
                        then
                           return True;
                        end if;
                     end loop;
                     return False;
                  end Declares;
               begin
                  for R of D.Relations loop
                     if R.To = Element_Index (I)
                       and then R.Kind in UML.Model.Inheritance
                                           | UML.Model.Realization
                     then
                        for M of D.Elements (Positive (R.From)).Members loop
                           if M.Kind = UML.Model.Method
                             and then M.Is_Abstract
                             and then not Declares (To_String (M.Id))
                           then
                              Report
                                ("concrete class '"
                                 & To_String (This.Id)
                                 & "' does not implement abstract method '"
                                 & To_String (M.Id)
                                 & "' (from '"
                                 & To_String
                                     (D.Elements (Positive (R.From)).Id)
                                 & "')");
                           end if;
                        end loop;
                     end if;
                  end loop;
               end;
            end if;
         end loop;
      end Check_Abstract_Impls;

   begin
      Check_Names;
      Check_Realizations;
      Check_Interface_Parents;
      Check_Multiple_Parents;
      Check_Cycles;
      Check_Abstract_Impls;

      if Errors > 0 then
         raise Validation_Error with
           Errors'Image & " validation error(s)";
      end if;
   end Validate;

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String)
   is
      Date_Str : Unbounded_String;
   begin
      Validate (D);

      declare
         Now : constant Ada.Calendar.Time := Ada.Calendar.Clock;
         Yr  : Ada.Calendar.Year_Number;
         Mn  : Ada.Calendar.Month_Number;
         Dd  : Ada.Calendar.Day_Number;
         Ss  : Ada.Calendar.Day_Duration;
      begin
         Ada.Calendar.Split (Now, Yr, Mn, Dd, Ss);
         Date_Str :=
           To_Unbounded_String
             (Ada.Strings.Fixed.Trim
                (Ada.Calendar.Year_Number'Image (Yr),
                 Ada.Strings.Both)
              & "-"
              & Ada.Strings.Fixed.Trim
                (Ada.Calendar.Month_Number'Image (Mn),
                 Ada.Strings.Both)
              & "-"
              & Ada.Strings.Fixed.Trim
                (Ada.Calendar.Day_Number'Image (Dd),
                 Ada.Strings.Both));
      end;

      declare
         Src_Dir   : constant String :=
           Ada.Directories.Compose (Out_Dir, "src");
         Tests_Dir : constant String :=
           Ada.Directories.Compose (Out_Dir, "tests");
         Machine_Name : constant String := Root_Package_Name (D);
      begin
         Ada.Directories.Create_Path (Src_Dir);
         Ada.Directories.Create_Path (Tests_Dir);

         --  Root package (holds top-level classifiers)
         Emit_Package (D, 0, Source_Diagram, To_String (Date_Str), Src_Dir);

         --  Each PlantUML package.
         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            if D.Elements (I).Kind = Package_Kind then
               Emit_Package (D, Element_Index (I),
                             Source_Diagram, To_String (Date_Str), Src_Dir);
            end if;
         end loop;

         --  Driver and setup
         Emit_Driver (D, Machine_Name, Tests_Dir);
         PlantUML2Code_Ada.Emit_Setup_Only (Out_Dir, Machine_Name);
      end;
   end Generate;

end PlantUML2Code_Ada_Classes;
