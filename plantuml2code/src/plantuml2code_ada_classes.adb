with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Calendar;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Characters.Handling;

with UML.Model;                use UML.Model;
with UML.Model.Queries;        use UML.Model.Queries;

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

   function Uses_Unbounded (Ret : String) return Boolean is
     (Ret = "Unbounded_String");

   --  =========================================================
   --  Helpers
   --  =========================================================
   function Id_Of (D : UML.Model.Diagram; Idx : Element_Index)
                   return String is
     (To_String (D.Elements (Positive (Idx)).Id));

   function Package_Of (D : UML.Model.Diagram; Idx : Element_Index)
                        return Element_Index is
   begin
      if Idx = 0 then
         return 0;
      end if;
      return D.Elements (Positive (Idx)).Parent;
   end Package_Of;

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
   function Has_Class_Parent (D : UML.Model.Diagram; Idx : Element_Index)
                              return Boolean is
   begin
      for R of D.Relations loop
         if R.To = Idx and then R.Kind = UML.Model.Inheritance then
            return True;
         end if;
      end loop;
      return False;
   end Has_Class_Parent;

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
   function Concrete_Methods_Of (D : UML.Model.Diagram; Idx : Element_Index)
                                 return Natural is
      N : Natural := 0;
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = UML.Model.Method
           and then not Member_Is_Abstract (M)
         then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Concrete_Methods_Of;

   --  Does this type have any inherited abstract methods that a
   --  concrete class must override? (returns count)
   function Missing_Abstract_Overrides (D : UML.Model.Diagram;
                                        Idx : Element_Index) return Natural
   is
      Missing : Natural := 0;

      function Declares (Name : String) return Boolean is
      begin
         for M of D.Elements (Positive (Idx)).Members loop
            if M.Kind = UML.Model.Method
              and then To_String (M.Id) = Name
            then
               return True;
            end if;
         end loop;
         return False;
      end Declares;
   begin
      --  Abstract methods on ancestors.
      for R of D.Relations loop
         if R.To = Idx
           and then R.Kind in UML.Model.Inheritance | UML.Model.Realization
         then
            for M of D.Elements (Positive (R.From)).Members loop
               if M.Kind = UML.Model.Method
                 and then Member_Is_Abstract (M)
                 and then not Declares (To_String (M.Id))
               then
                  Missing := Missing + 1;
               end if;
            end loop;
         end if;
      end loop;
      return Missing;
   end Missing_Abstract_Overrides;

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
      R : Unbounded_String;
      First : Boolean := True;
   begin
      Append (R, "   type " & Ident (Id_Of (D, Idx)) & " is (");
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = UML.Model.Enum_Literal then
            if not First then
               Append (R, ", ");
            end if;
            Append (R, Ident (To_String (M.Id)));
            First := False;
         end if;
      end loop;
      Append (R, ");");
      return To_String (R);
   end Enum_Decl;

   function Interface_Decl (D : UML.Model.Diagram; Idx : Element_Index)
                            return String
   is
      Name : constant String := Ident (Id_Of (D, Idx));
      R    : Unbounded_String;
   begin
      Append (R, "   type " & Name & " is limited interface;");
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = UML.Model.Method then
            declare
               M_Name : constant String := Sanitize (To_String (M.Id));
               Ret    : constant String := Map_Type (To_String (M.Type_Name));
            begin
               Append (R, ASCII.LF & ASCII.LF & "   ");
               if Ret'Length = 0 then
                  Append (R, "procedure " & M_Name
                          & " (Self : in out " & Name & ") is abstract;");
               else
                  Append (R, "function " & M_Name
                          & " (Self : in out " & Name & ") return "
                          & Ret & " is abstract;");
               end if;
            end;
         end if;
      end loop;
      return To_String (R);
   end Interface_Decl;

   function Class_Decl (D : UML.Model.Diagram; Idx : Element_Index)
                        return String
   is
      Name : constant String := Ident (Id_Of (D, Idx));
      E    : constant Element := D.Elements (Positive (Idx));
      R    : Unbounded_String;

      Is_Abstract : constant Boolean := E.Kind = Abstract_Class;

      Parent_Idx : constant Element_Index := First_Parent (D, Idx);
      Interfaces : constant Element_Index_Vectors.Vector :=
        Interfaces_Of (D, Idx);

      Has_Parent : constant Boolean := Parent_Idx /= 0;
      Has_Deriv  : constant Boolean :=
        Has_Parent or else not Interfaces.Is_Empty;

      First_Deriv : Boolean := True;
   begin
      Append (R, "   type " & Name & " is");
      if Is_Abstract then
         Append (R, " abstract");
      end if;

      if not Has_Deriv then
         Append (R, " tagged");
      else
         if Has_Parent then
            Append (R, " new " & Ident (Id_Of (D, Parent_Idx)));
            First_Deriv := False;
         end if;
         for I of Interfaces loop
            if First_Deriv then
               Append (R, " new " & Ident (Id_Of (D, I)));
               First_Deriv := False;
            else
               Append (R, " and " & Ident (Id_Of (D, I)));
            end if;
         end loop;
      end if;

      if Field_Count (D, Idx) = 0 then
         if Has_Deriv then
            Append (R, " with null record;");
         else
            Append (R, " null record;");
         end if;
      else
         if Has_Deriv then
            Append (R, " with record" & ASCII.LF);
         else
            Append (R, " record" & ASCII.LF);
         end if;
         for M of E.Members loop
            if M.Kind = UML.Model.Attribute then
               Append (R, "      Attr_" & Ident (To_String (M.Id))
                       & " : " & Map_Type (To_String (M.Type_Name))
                       & ";" & ASCII.LF);
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
                  Append (R, "      Attr_" & Target_Name & " : ");
                  if Target_Kind = Enumeration then
                     Append (R, Target_Name & ";" & ASCII.LF);
                  else
                     Append (R, "access " & Target_Name
                             & "'Class;" & ASCII.LF);
                  end if;
               end;
            end if;
         end loop;
         Append (R, "   end record;");
      end if;

      for M of E.Members loop
         if M.Kind = UML.Model.Method then
            declare
               M_Name  : constant String := Ident (To_String (M.Id));
               Ret     : constant String :=
                 Map_Type (To_String (M.Type_Name));
               Is_Abs  : constant Boolean := Member_Is_Abstract (M);
            begin
               Append (R, ASCII.LF & ASCII.LF);
               if Is_Override (D, Idx, To_String (M.Id)) then
                  Append (R, "   overriding" & ASCII.LF);
               end if;
               if Ret'Length = 0 then
                  Append (R, "   procedure " & M_Name
                          & " (Self : in out " & Name & ")");
               else
                  Append (R, "   function " & M_Name
                          & " (Self : in out " & Name & ") return "
                          & Ret);
               end if;
               if Is_Abs then
                  Append (R, " is abstract;");
               else
                  Append (R, ";");
               end if;
            end;
         end if;
      end loop;

      return To_String (R);
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
   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String)
   is
      Date_Str : Unbounded_String;
   begin
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
