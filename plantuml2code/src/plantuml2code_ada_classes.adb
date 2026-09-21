with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Calendar;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Containers.Vectors;

with UML.Model;                use UML.Model;
with PlantUML2Code_Utils;
with PlantUML2Code_Template_Path;
with PlantUML2Code_Ada;      use PlantUML2Code_Utils;
with Templates_Parser;         use Templates_Parser;

package body PlantUML2Code_Ada_Classes is

   --  Local alias: UML.Model.Element. Ada.Strings.Unbounded.Element is
   --  a function with the same name; this shadows it locally so type
   --  positions resolve to the model type. Qualified calls to the
   --  function (Ada.Strings.Unbounded.Element (...)) still resolve.
   subtype Element is UML.Model.Element;

   function Id_Of (D : UML.Model.Diagram; Idx : Element_Index)
                   return String is
     (To_String (D.Elements (Positive (Idx)).Id));

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
         while Length (Tmp) > 0 and then Ada.Strings.Unbounded.Element (Tmp, Length (Tmp)) = '_' loop
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

   function Map_Type (S : String) return String is
      Lower : String (S'Range);
   begin
      if S'Length = 0 then
         return "Integer";
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
      elsif Ada.Strings.Fixed.Index (Lower, "int") > 0
        or else Ada.Strings.Fixed.Index (Lower, "long") > 0
        or else Ada.Strings.Fixed.Index (Lower, "short") > 0
      then
         return "Integer";
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

   function Returns_Nothing (M : Member) return Boolean is
     (Length (M.Type_Name) = 0 or else To_String (M.Type_Name) = "void");

   function Parents_Of (D : UML.Model.Diagram; Name : String)
                        return Unbounded_String
   is
      Result : Unbounded_String;
   begin
      for R of D.Relations loop
         if Id_Of (D, R.To) = Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            if Length (Result) > 0 then
               Append (Result, " and ");
            end if;
            Append (Result, Sanitize (Id_Of (D, R.From)) & ".T");
         end if;
      end loop;
      return Result;
   end Parents_Of;

   function Has_Attributes (D : UML.Model.Diagram; Idx : Element_Index)
                            return Boolean
   is
      Self_Name : constant String :=
        To_String (D.Elements (Positive (Idx)).Id);
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = Attribute then
            return True;
         end if;
      end loop;

      for R of D.Relations loop
         if Id_Of (D, R.From) = Self_Name
           and then R.Kind in Composition | Aggregation | UML.Model.Association
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Attributes;

   function Uses_Unbounded (D : UML.Model.Diagram; Idx : Element_Index)
                            return Boolean
   is
      This_Name : constant String :=
        To_String (D.Elements (Positive (Idx)).Id);
   begin
      --  Own members
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind in Attribute | Method
           and then Map_Type (To_String (M.Type_Name)) = "Unbounded_String"
         then
            return True;
         end if;
      end loop;

      --  Inherited methods
      for R of D.Relations loop
         if Id_Of (D, R.To) = This_Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            for P of D.Elements loop
               if To_String (P.Id) = Id_Of (D, R.From) then
                  for M of P.Members loop
                     if M.Kind = Method
                       and then Map_Type (To_String (M.Type_Name))
                                = "Unbounded_String"
                     then
                        return True;
                     end if;
                  end loop;
               end if;
            end loop;
         end if;
      end loop;

      return False;
   end Uses_Unbounded;

   function Relation_Field_Type
     (D : UML.Model.Diagram; Target_Name : String) return String
   is
      Target_Kind : Element_Kind := Class;
   begin
      for K of D.Elements loop
         if To_String (K.Id) = Target_Name then
            Target_Kind := K.Kind;
            exit;
         end if;
      end loop;

      if Target_Kind = Enumeration then
         return Sanitize (Target_Name) & ".T";
      else
         return "access " & Sanitize (Target_Name) & ".T'Class";
      end if;
   end Relation_Field_Type;

   function Record_Fields (D : UML.Model.Diagram; Idx : Element_Index)
                            return String
   is
      R : Unbounded_String;
      First : Boolean := True;
      Self_Name : constant String :=
        To_String (D.Elements (Positive (Idx)).Id);
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = Attribute then
            if not First then
               Append (R, ASCII.LF & "      ");
            end if;
            First := False;
            Append (R, "Attr_" & Sanitize (To_String (M.Id))
                    & " : "
                    & Map_Type (To_String (M.Type_Name)) & ";");
         end if;
      end loop;

      for Rel of D.Relations loop
         if Id_Of (D, Rel.From) = Self_Name
           and then Rel.Kind in Composition | Aggregation | UML.Model.Association
           and then Id_Of (D, Rel.To) /= Self_Name
         then
            declare
               Target : constant String := Id_Of (D, Rel.To);
            begin
               if not First then
                  Append (R, ASCII.LF & "      ");
               end if;
               First := False;
               Append (R, "Attr_" & Sanitize (Target)
                       & " : " & Relation_Field_Type (D, Target) & ";");
            end;
         end if;
      end loop;

      return To_String (R);
   end Record_Fields;

   function Type_Decl (D : UML.Model.Diagram; Idx : Element_Index)
                       return String
   is
      K : constant Element := D.Elements (Positive (Idx));
      Parents : constant String :=
        To_String (Parents_Of (D, To_String (K.Id)));
      Has_Attrs : constant Boolean := Has_Attributes (D, Idx);
   begin
      case K.Kind is
         when Interface_Kind =>
            return "   type T is limited interface"
                 & " and Class_Runtime.Object;";

         when Enumeration =>
            declare
               R : Unbounded_String;
               First : Boolean := True;
            begin
               for M of K.Members loop
                  if M.Kind = Enum_Literal then
                     if not First then
                        Append (R, ", ");
                     end if;
                     First := False;
                     Append (R, Sanitize (To_String (M.Id)));
                  end if;
               end loop;
               return "   type T is (" & To_String (R) & ");";
            end;

         when Abstract_Class =>
            if Parents'Length = 0 then
               if Has_Attrs then
                  return "   type T is abstract new Class_Runtime.Object"
                       & " with record"
                       & ASCII.LF & "      "
                       & Record_Fields (D, Idx)
                       & ASCII.LF & "   end record;";
               else
                  return "   type T is abstract new Class_Runtime.Object"
                       & " with null record;";
               end if;
            else
               if Has_Attrs then
                  return "   type T is abstract new " & Parents
                       & " with record"
                       & ASCII.LF & "      "
                       & Record_Fields (D, Idx)
                       & ASCII.LF & "   end record;";
               else
                  return "   type T is abstract new " & Parents
                       & " with null record;";
               end if;
            end if;

         when others =>
            if Parents'Length = 0 then
               if Has_Attrs then
                  return "   type T is new Class_Runtime.Object"
                       & " with record"
                       & ASCII.LF & "      "
                       & Record_Fields (D, Idx)
                       & ASCII.LF & "   end record;";
               else
                  return "   type T is new Class_Runtime.Object"
                       & " with null record;";
               end if;
            else
               if Has_Attrs then
                  return "   type T is new " & Parents
                       & " with record"
                       & ASCII.LF & "      "
                       & Record_Fields (D, Idx)
                       & ASCII.LF & "   end record;";
               else
                  return "   type T is new " & Parents
                       & " with null record;";
               end if;
            end if;
      end case;
   end Type_Decl;

   function Has_Parent_Method (D : UML.Model.Diagram; Name, Method_Name : String)
                               return Boolean
   is
   begin
      for R of D.Relations loop
         if Id_Of (D, R.To) = Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            for K of D.Elements loop
               if To_String (K.Id) = Id_Of (D, R.From) then
                  for M of K.Members loop
                     if M.Kind = Method
                       and then Sanitize (To_String (M.Id))
                             = Sanitize (Method_Name)
                     then
                        return True;
                     end if;
                  end loop;
               end if;
            end loop;
         end if;
      end loop;
      return False;
   end Has_Parent_Method;

   --  Returns a list of (Parent_Package, Method_Name) for all abstract
   --  methods inherited from parents that this class has not overridden.
   type Inherited_Method is record
      Pkg  : Unbounded_String;
      Name : Unbounded_String;
      Ret  : Unbounded_String;
      Is_Proc : Boolean;
   end record;

   package Inherited_Vectors is new
     Ada.Containers.Vectors (Positive, Inherited_Method);

   function Inherited_Abstracts (D : UML.Model.Diagram; Idx : Element_Index)
                                 return Inherited_Vectors.Vector
   is
      Result : Inherited_Vectors.Vector;
      This_Name : constant String :=
        To_String (D.Elements (Positive (Idx)).Id);

      function Has_Override (Method_Name : String) return Boolean is
      begin
         for M of D.Elements (Positive (Idx)).Members loop
            if M.Kind = Method
              and then Sanitize (To_String (M.Id)) = Sanitize (Method_Name)
            then
               return True;
            end if;
         end loop;
         return False;
      end Has_Override;

      function Already_Added (Pkg, Name : String) return Boolean is
      begin
         for I in Result.First_Index .. Result.Last_Index loop
            if To_String (Result (I).Pkg) = Pkg
              and then To_String (Result (I).Name) = Name
            then
               return True;
            end if;
         end loop;
         return False;
      end Already_Added;

   begin
      for R of D.Relations loop
         if Id_Of (D, R.To) = This_Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            declare
               Parent_Pkg : constant String :=
                 Sanitize (Id_Of (D, R.From));
            begin
               for P of D.Elements loop
                  if To_String (P.Id) = Id_Of (D, R.From) then
                     for M of P.Members loop
                        if M.Kind = Method
                          and then (M.Is_Abstract
                                    or else P.Kind = Interface_Kind)
                          and then not Has_Override (To_String (M.Id))
                          and then not Already_Added
                            (Parent_Pkg, Sanitize (To_String (M.Id)))
                        then
                           Result.Append
                             (Inherited_Method'
                                (Pkg     => To_Unbounded_String (Parent_Pkg),
                                 Name    => To_Unbounded_String
                                              (Sanitize (To_String (M.Id))),
                                 Ret     => To_Unbounded_String
                                              (Map_Type (To_String (M.Type_Name))),
                                 Is_Proc => Length (M.Type_Name) = 0
                                            or else To_String (M.Type_Name) = "void"));
                        end if;
                     end loop;
                  end if;
               end loop;
            end;
         end if;
      end loop;
      return Result;
   end Inherited_Abstracts;

   function Method_Decls (D : UML.Model.Diagram; Idx : Element_Index)
                          return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        To_String (D.Elements (Positive (Idx)).Id);
      Is_Interface : constant Boolean :=
        D.Elements (Positive (Idx)).Kind = Interface_Kind;
      Is_Abstract_Type : constant Boolean :=
        D.Elements (Positive (Idx)).Kind = Abstract_Class;
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = Method then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Has_Parent : constant Boolean :=
                 Has_Parent_Method (D, Class_Name, To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean := Returns_Nothing (M);
            begin
               if Has_Parent then
                  Append (R, "   overriding" & ASCII.LF);
               end if;
               if Is_Proc then
                  Append (R, "   procedure " & Name
                         & " (Self : in out T)");
               else
                  Append (R, "   function " & Name
                         & " (Self : in out T) return " & Ret);
               end if;
               if M.Is_Abstract or else Is_Interface then
                  Append (R, " is abstract;" & ASCII.LF);
               else
                  Append (R, ";" & ASCII.LF);
               end if;
            end;
         end if;
      end loop;

      if Is_Interface then
         Append (R, "   overriding" & ASCII.LF
                 & "   function Class_Name (Self : T) return String"
                 & " is abstract;" & ASCII.LF);
         --  Class_Runtime.Object already declares Class_Name abstract;
         --  restating it here is legal and needed for the interface.
      end if;

      --  Inherited abstract methods not overridden here: emit overrides
      --  so a concrete derived type compiles.
      if not Is_Abstract_Type then
         declare
            Inherited : constant Inherited_Vectors.Vector :=
              Inherited_Abstracts (D, Idx);
         begin
            for I in Inherited.First_Index .. Inherited.Last_Index loop
               declare
                  IM : constant Inherited_Method := Inherited (I);
               begin
                  Append (R, "   overriding" & ASCII.LF);
                  if IM.Is_Proc then
                     Append (R, "   procedure " & To_String (IM.Name)
                             & " (Self : in out T);" & ASCII.LF);
                  else
                     Append (R, "   function " & To_String (IM.Name)
                             & " (Self : in out T) return "
                             & To_String (IM.Ret) & ";" & ASCII.LF);
                  end if;
               end;
            end loop;
         end;
      end if;

      return To_String (R);
   end Method_Decls;

   function Method_Bodies (D : UML.Model.Diagram; Idx : Element_Index)
                           return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Elements (Positive (Idx)).Id));
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = Method and then not M.Is_Abstract then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean := Returns_Nothing (M);
            begin
               if Is_Proc then
                  Append (R, "   procedure " & Name
                         & " (Self : in out T) is" & ASCII.LF
                         & "   begin" & ASCII.LF
                         & "      " & Class_Name & "_Actions."
                         & Name & " (Self);" & ASCII.LF
                         & "   end " & Name & ";" & ASCII.LF & ASCII.LF);
               else
                  Append (R, "   function " & Name
                         & " (Self : in out T) return " & Ret
                         & " is" & ASCII.LF
                         & "   begin" & ASCII.LF
                         & "      return " & Class_Name & "_Actions."
                         & Name & " (Self);" & ASCII.LF
                         & "   end " & Name & ";" & ASCII.LF & ASCII.LF);
               end if;
            end;
         end if;
      end loop;

      declare
         Inherited : constant Inherited_Vectors.Vector :=
           Inherited_Abstracts (D, Idx);
      begin
         for I in Inherited.First_Index .. Inherited.Last_Index loop
            declare
               IM : constant Inherited_Method := Inherited (I);
               Name : constant String := To_String (IM.Name);
            begin
               if IM.Is_Proc then
                  Append (R, "   procedure " & Name
                         & " (Self : in out T) is" & ASCII.LF
                         & "   begin" & ASCII.LF
                         & "      " & Class_Name & "_Actions."
                         & Name & " (Self);" & ASCII.LF
                         & "   end " & Name & ";" & ASCII.LF & ASCII.LF);
               else
                  Append (R, "   function " & Name
                         & " (Self : in out T) return "
                         & To_String (IM.Ret) & " is" & ASCII.LF
                         & "   begin" & ASCII.LF
                         & "      return " & Class_Name & "_Actions."
                         & Name & " (Self);" & ASCII.LF
                         & "   end " & Name & ";" & ASCII.LF & ASCII.LF);
               end if;
            end;
         end loop;
      end;
      return To_String (R);
   end Method_Bodies;

   function Actions_Inherited_Decls (D : UML.Model.Diagram; Idx : Element_Index)
                                     return String;
   function Actions_Inherited_Bodies (D : UML.Model.Diagram; Idx : Element_Index)
                                      return String;

   function Actions_Decls (D : UML.Model.Diagram; Idx : Element_Index)
                           return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Elements (Positive (Idx)).Id));
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = Method and then not M.Is_Abstract then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean := Returns_Nothing (M);
            begin
               if Is_Proc then
                  Append (R, "   procedure " & Name
                         & " (Self : in out " & Class_Name & ".T);"
                         & ASCII.LF);
               else
                  Append (R, "   function " & Name
                         & " (Self : in out " & Class_Name & ".T)"
                         & " return " & Ret & ";" & ASCII.LF);
               end if;
            end;
         end if;
      end loop;
      Append (R, Actions_Inherited_Decls (D, Idx));
      return To_String (R);
   end Actions_Decls;

   --  Also expose the inherited-abstract overrides through Actions so
   --  the user can implement them per concrete class.
   function Actions_Inherited_Decls (D : UML.Model.Diagram; Idx : Element_Index)
                                     return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Elements (Positive (Idx)).Id));
      Inherited : constant Inherited_Vectors.Vector :=
        Inherited_Abstracts (D, Idx);
   begin
      for I in Inherited.First_Index .. Inherited.Last_Index loop
         declare
            IM : constant Inherited_Method := Inherited (I);
         begin
            if IM.Is_Proc then
               Append (R, "   procedure " & To_String (IM.Name)
                      & " (Self : in out " & Class_Name & ".T);"
                      & ASCII.LF);
            else
               Append (R, "   function " & To_String (IM.Name)
                      & " (Self : in out " & Class_Name & ".T)"
                      & " return " & To_String (IM.Ret) & ";" & ASCII.LF);
            end if;
         end;
      end loop;
      return To_String (R);
   end Actions_Inherited_Decls;

   function Actions_Inherited_Bodies (D : UML.Model.Diagram; Idx : Element_Index)
                                      return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Elements (Positive (Idx)).Id));
      Inherited : constant Inherited_Vectors.Vector :=
        Inherited_Abstracts (D, Idx);
   begin
      for I in Inherited.First_Index .. Inherited.Last_Index loop
         declare
            IM : constant Inherited_Method := Inherited (I);
         begin
            if IM.Is_Proc then
               Append (R, "   procedure " & To_String (IM.Name)
                      & " (Self : in out " & Class_Name & ".T) is"
                      & ASCII.LF
                      & "   begin" & ASCII.LF
                      & "      raise Program_Error with """
                      & Class_Name & "." & To_String (IM.Name)
                      & " not implemented"";" & ASCII.LF
                      & "   end " & To_String (IM.Name) & ";"
                      & ASCII.LF & ASCII.LF);
            else
               Append (R, "   function " & To_String (IM.Name)
                      & " (Self : in out " & Class_Name & ".T)"
                      & " return " & To_String (IM.Ret) & " is"
                      & ASCII.LF
                      & "   begin" & ASCII.LF
                      & "      raise Program_Error with """
                      & Class_Name & "." & To_String (IM.Name)
                      & " not implemented"";" & ASCII.LF
                      & "      return " & Dummy_Value (To_String (IM.Ret))
                      & ";" & ASCII.LF
                      & "   end " & To_String (IM.Name) & ";"
                      & ASCII.LF & ASCII.LF);
            end if;
         end;
      end loop;
      return To_String (R);
   end Actions_Inherited_Bodies;

   function Actions_Bodies (D : UML.Model.Diagram; Idx : Element_Index)
                            return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Elements (Positive (Idx)).Id));
   begin
      for M of D.Elements (Positive (Idx)).Members loop
         if M.Kind = Method and then not M.Is_Abstract then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean := Returns_Nothing (M);
            begin
               if Is_Proc then
                  Append (R, "   procedure " & Name
                         & " (Self : in out " & Class_Name & ".T) is"
                         & ASCII.LF
                         & "   begin" & ASCII.LF
                         & "      raise Program_Error with """
                         & Class_Name & "." & Name
                         & " not implemented"";" & ASCII.LF
                         & "   end " & Name & ";" & ASCII.LF & ASCII.LF);
               else
                  Append (R, "   function " & Name
                         & " (Self : in out " & Class_Name & ".T)"
                         & " return " & Ret & " is" & ASCII.LF
                         & "   begin" & ASCII.LF
                         & "      raise Program_Error with """
                         & Class_Name & "." & Name
                         & " not implemented"";" & ASCII.LF
                         & "      return " & Dummy_Value (Ret) & ";"
                         & ASCII.LF
                         & "   end " & Name & ";" & ASCII.LF & ASCII.LF);
               end if;
            end;
         end if;
      end loop;
      Append (R, Actions_Inherited_Bodies (D, Idx));
      return To_String (R);
   end Actions_Bodies;

   function With_Clauses (D : UML.Model.Diagram; Idx : Element_Index)
                          return String
   is
      R : Unbounded_String;
      K : constant Element := D.Elements (Positive (Idx));
   begin
      --  Only root classes actually reference Class_Runtime in their
      --  spec. Derived classes inherit it indirectly.
      declare
         Parents : constant String :=
           To_String (Parents_Of (D, To_String (K.Id)));
      begin
         if Parents'Length = 0 then
            Append (R, "with Class_Runtime;" & ASCII.LF);
         end if;
      end;
      if Uses_Unbounded (D, Idx) then
         Append (R, "with Ada.Strings.Unbounded;"
                 & "  use Ada.Strings.Unbounded;" & ASCII.LF);
      end if;
      --  Parents: parse comma/and-separated list; simplest to iterate
      --  relations again to get each parent's package name.
      for Rel of D.Relations loop
         if Id_Of (D, Rel.To) = To_String (K.Id)
           and then (Rel.Kind = Inheritance or else Rel.Kind = Realization)
         then
            Append (R, "with " & Sanitize (Id_Of (D, Rel.From))
                    & ";" & ASCII.LF);
         end if;
      end loop;
      declare
         package IV is new Ada.Containers.Vectors
           (Positive, Element_Index);
         Self_Name : constant String := To_String (K.Id);
         Seen : IV.Vector;
      begin
         for Rel of D.Relations loop
            if Id_Of (D, Rel.From) = Self_Name
              and then Rel.Kind in Composition | Aggregation | UML.Model.Association
              and then Id_Of (D, Rel.To) /= Self_Name
            then
               declare
                  Already : Boolean := False;
               begin
                  for S of Seen loop
                     if S = Rel.To then
                        Already := True;
                        exit;
                     end if;
                  end loop;
                  if not Already then
                     Seen.Append (Rel.To);
                     Append (R, "with " & Sanitize (Id_Of (D, Rel.To))
                             & ";" & ASCII.LF);
                  end if;
               end;
            end if;
         end loop;
      end;

      if Length (R) > 0 then
         Append (R, ASCII.LF);
      end if;
      return To_String (R);
   end With_Clauses;

   procedure Render_To
     (Template : String;
      Output   : String;
      T        : Translate_Set)
   is
      Content : constant String := Render_Template ("ada", Template, T);
      F       : File_Type;
   begin
      Create (F, Out_File, Output);
      Put (F, Content);
      Close (F);
      Put_Line ("wrote " & Output);
   end Render_To;

   procedure Render_If_Missing
     (Template : String;
      Output   : String;
      T        : Translate_Set)
   is
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
      else
         Render_To (Template, Output, T);
      end if;
   end Render_If_Missing;

   procedure Emit_One (D : UML.Model.Diagram; Idx : Element_Index;
                       Source_Diagram, Date_Str, Out_Dir : String)
   is
      K : constant Element := D.Elements (Positive (Idx));
      Class_Name : constant String := Sanitize (To_String (K.Id));
      T : Translate_Set;

      Ads_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Class_Name & ".ads");
      Adb_File : constant String :=
        Ada.Directories.Compose (Out_Dir, Class_Name & ".adb");
      Act_Ads : constant String :=
        Ada.Directories.Compose (Out_Dir, Class_Name & "_Actions.ads");
      Act_Adb : constant String :=
        Ada.Directories.Compose (Out_Dir, Class_Name & "_Actions.adb");

      Has_Methods : Boolean := False;
   begin
      Insert (T, Assoc ("CLASS_NAME", Class_Name));
      Insert (T, Assoc ("SOURCE_DIAGRAM", Source_Diagram));
      Insert (T, Assoc ("GENERATION_DATE", Date_Str));

      for M of K.Members loop
         if M.Kind = Method and then not M.Is_Abstract then
            Has_Methods := True;
         end if;
      end loop;

      --  Interface: no body, no actions
      if K.Kind = Interface_Kind then
         Insert (T, Assoc ("WITH_CLAUSES", With_Clauses (D, Idx)));
         Insert (T, Assoc ("TYPE_DECL", Type_Decl (D, Idx)));
         Insert (T, Assoc ("METHOD_DECLS", Method_Decls (D, Idx)));
         Render_To ("class_interface.ads.tmplt", Ads_File, T);
         return;
      end if;

      --  Enumeration: spec + minimal body for Class_Name
      if K.Kind = Enumeration then
         Insert (T, Assoc ("TYPE_DECL", Type_Decl (D, Idx)));
         Render_To ("class_enum.ads.tmplt", Ads_File, T);
         Render_To ("class_enum.adb.tmplt", Adb_File, T);
         return;
      end if;

      --  Regular or abstract class
      Insert (T, Assoc ("WITH_CLAUSES", With_Clauses (D, Idx)));
      Insert (T, Assoc ("TYPE_DECL", Type_Decl (D, Idx)));
      Insert (T, Assoc ("METHOD_DECLS", Method_Decls (D, Idx)));
      Insert (T, Assoc ("BODY_WITH",
                        (if Has_Methods
                         then "with " & Class_Name & "_Actions;"
                              & ASCII.LF & ASCII.LF
                         else "")));
      Render_To ("class.ads.tmplt", Ads_File, T);

      --  Always emit a body: Class_Name lives there even when the
      --  class has no methods.
      declare
         Bodies : constant String := Method_Bodies (D, Idx);
         Body_Text : constant String :=
           Bodies
           & "   overriding" & ASCII.LF
           & "   function Class_Name (Self : T) return String is"
           & ASCII.LF
           & "      pragma Unreferenced (Self);" & ASCII.LF
           & "   begin" & ASCII.LF
           & "      return """
           & Sanitize (To_String (K.Id)) & """;" & ASCII.LF
           & "   end Class_Name;" & ASCII.LF;
      begin
         Insert (T, Assoc ("METHOD_BODIES", Body_Text));
      end;
      Render_To ("class.adb.tmplt", Adb_File, T);

      --  Actions files are only useful when there is something to
      --  implement. Skip them for method-less classes.
      if Has_Methods then
         Insert (T, Assoc ("METHOD_DECLS", Actions_Decls (D, Idx)));
         Render_If_Missing ("class_actions.ads.tmplt", Act_Ads, T);

         Insert (T, Assoc ("METHOD_BODIES", Actions_Bodies (D, Idx)));
         Render_If_Missing ("class_actions.adb.tmplt", Act_Adb, T);
      end if;
   end Emit_One;

   procedure Emit_Class_Runtime (Src_Dir : String) is
      Empty_Set : Translate_Set;

      procedure One (Tmpl, File_Name : String) is
         Output : constant String :=
           Ada.Directories.Compose (Src_Dir, File_Name);
         Path   : constant String :=
           PlantUML2Code_Template_Path.Locate ("ada/runtime", Tmpl);
         Content : constant String :=
           Templates_Parser.Parse (Path, Empty_Set);
         F : File_Type;
      begin
         if Ada.Directories.Exists (Output) then
            Put_Line ("kept  " & Output);
         else
            Create (F, Out_File, Output);
            Put (F, Content);
            Close (F);
            Put_Line ("wrote " & Output);
         end if;
      end One;
   begin
      One ("class_runtime.ads.tmplt", "class_runtime.ads");
      One ("class_runtime-tracing.ads.tmplt",
           "class_runtime-tracing.ads");
      One ("class_runtime-tracing.adb.tmplt",
           "class_runtime-tracing.adb");
   end Emit_Class_Runtime;

   procedure Emit_Class_Driver
     (Tests_Dir, Out_Dir : String; D : UML.Model.Diagram)
   is
      pragma Unreferenced (Out_Dir);
      Output : constant String :=
        Ada.Directories.Compose (Tests_Dir, "driver.adb");
      Path   : constant String :=
        PlantUML2Code_Template_Path.Locate ("ada/project",
                                            "driver_class.adb.tmplt");
      T      : Translate_Set;

      Withs  : Unbounded_String;
      Insts  : Unbounded_String;
      Model  : constant String :=
        (if Length (D.Id) > 0
         then To_String (D.Id) else "Model");
      F : File_Type;
   begin
      if Ada.Directories.Exists (Output) then
         Put_Line ("kept  " & Output);
         return;
      end if;

      for K of D.Elements loop
         if K.Kind in Class | Record_Type then
            --  Construct only concrete class and record types.
            declare
               N : constant String := Sanitize (To_String (K.Id));
            begin
               Append (Withs, "with " & N & ";" & ASCII.LF);
               Append (Insts, "   declare" & ASCII.LF
                       & "      X : " & N & ".T;" & ASCII.LF
                       & "      pragma Unreferenced (X);" & ASCII.LF
                       & "   begin" & ASCII.LF
                       & "      Put_Line (" & '"' & N
                       & ": "" & " & N & ".Class_Name (X));"
                       & ASCII.LF
                       & "   end;" & ASCII.LF);
            end;
         elsif K.Kind = Enumeration then
            --  Enums are concrete too; just reference the type.
            declare
               N : constant String := Sanitize (To_String (K.Id));
            begin
               Append (Withs, "with " & N & ";" & ASCII.LF);
               Append (Insts, "   Put_Line (" & '"' & N
                       & ": "" & " & N
                       & ".Class_Name (" & N & ".T'First));"
                       & ASCII.LF);
            end;
         end if;
      end loop;

      Insert (T, Assoc ("MODEL_NAME", Model));
      Insert (T, Assoc ("DRIVER_WITH_CLAUSES", To_String (Withs)));
      Insert (T, Assoc ("DRIVER_INSTANTIATIONS", To_String (Insts)));

      declare
         Content : constant String :=
           Templates_Parser.Parse (Path, T);
      begin
         Create (F, Out_File, Output);
         Put (F, Content);
         Close (F);
      end;
      Put_Line ("wrote " & Output);
   end Emit_Class_Driver;

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
         Machine_Name : constant String :=
           (if Length (D.Id) > 0
            then To_String (D.Id) else "Model");
      begin
         Ada.Directories.Create_Path (Src_Dir);
         Ada.Directories.Create_Path (Tests_Dir);

         --  Class runtime is separate from state machine runtime.
         Emit_Class_Runtime (Src_Dir);
         Emit_Class_Driver (Tests_Dir, Out_Dir, D);
         PlantUML2Code_Ada.Emit_Setup_Only (Out_Dir, Machine_Name);

         for I in D.Elements.First_Index .. D.Elements.Last_Index loop
            if D.Elements (I).Kind /= Package_Kind then
               Emit_One (D, Element_Index (I), Source_Diagram,
                         To_String (Date_Str), Src_Dir);
            end if;
         end loop;
      end;
   end Generate;

end PlantUML2Code_Ada_Classes;
