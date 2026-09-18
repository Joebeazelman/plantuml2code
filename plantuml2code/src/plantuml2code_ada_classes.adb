with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Calendar;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Strings.Fixed;
with Ada.Containers.Vectors;

with PlantUML.Classes;         use PlantUML.Classes;
with PlantUML2Code_Utils;      use PlantUML2Code_Utils;
with Templates_Parser;         use Templates_Parser;

package body PlantUML2Code_Ada_Classes is

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
         while Length (Tmp) > 0 and then Element (Tmp, Length (Tmp)) = '_' loop
            Delete (Tmp, Length (Tmp), Length (Tmp));
         end loop;
         if Length (Tmp) = 0 then
            return "Unnamed";
         end if;
         if Element (Tmp, 1) in '0' .. '9' then
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

   function Parents_Of (D : Class_Diagram; Name : String)
                        return Unbounded_String
   is
      Result : Unbounded_String;
   begin
      for R of D.Relations loop
         if To_String (R.To) = Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            if Length (Result) > 0 then
               Append (Result, " and ");
            end if;
            Append (Result, Sanitize (To_String (R.From)) & ".T");
         end if;
      end loop;
      return Result;
   end Parents_Of;

   function Has_Attributes (D : Class_Diagram; Idx : Class_Index)
                            return Boolean
   is
   begin
      for M of D.Pool (Positive (Idx)).Members loop
         if M.Kind = Attribute then
            return True;
         end if;
      end loop;
      return False;
   end Has_Attributes;

   function Uses_Unbounded (D : Class_Diagram; Idx : Class_Index)
                            return Boolean
   is
      This_Name : constant String :=
        To_String (D.Pool (Positive (Idx)).Id);
   begin
      --  Own members
      for M of D.Pool (Positive (Idx)).Members loop
         if M.Kind in Attribute | Method
           and then Map_Type (To_String (M.Type_Name)) = "Unbounded_String"
         then
            return True;
         end if;
      end loop;

      --  Inherited methods
      for R of D.Relations loop
         if To_String (R.To) = This_Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            for P of D.Pool loop
               if To_String (P.Id) = To_String (R.From) then
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

   function Record_Fields (D : Class_Diagram; Idx : Class_Index)
                            return String
   is
      R : Unbounded_String;
      First : Boolean := True;
   begin
      for M of D.Pool (Positive (Idx)).Members loop
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
      return To_String (R);
   end Record_Fields;

   function Type_Decl (D : Class_Diagram; Idx : Class_Index)
                       return String
   is
      K : constant Classifier := D.Pool (Positive (Idx));
      Parents : constant String :=
        To_String (Parents_Of (D, To_String (K.Id)));
      Has_Attrs : constant Boolean := Has_Attributes (D, Idx);
   begin
      case K.Kind is
         when Interface_Kind =>
            return "   type T is interface;";

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
                  return "   type T is abstract tagged record"
                       & ASCII.LF & "      "
                       & Record_Fields (D, Idx)
                       & ASCII.LF & "   end record;";
               else
                  return "   type T is abstract tagged null record;";
               end if;
            else
               return "   type T is abstract new " & Parents
                    & " with null record;";
            end if;

         when others =>
            if Parents'Length = 0 then
               if Has_Attrs then
                  return "   type T is tagged record"
                       & ASCII.LF & "      "
                       & Record_Fields (D, Idx)
                       & ASCII.LF & "   end record;";
               else
                  return "   type T is tagged null record;";
               end if;
            else
               return "   type T is new " & Parents
                    & " with null record;";
            end if;
      end case;
   end Type_Decl;

   function Has_Parents (D : Class_Diagram; Idx : Class_Index)
                         return Boolean
   is
     (Length (Parents_Of
                (D, To_String (D.Pool (Positive (Idx)).Id))) > 0);

   function Has_Parent_Method (D : Class_Diagram; Name, Method_Name : String)
                               return Boolean
   is
   begin
      for R of D.Relations loop
         if To_String (R.To) = Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            for K of D.Pool loop
               if To_String (K.Id) = To_String (R.From) then
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

   function Inherited_Abstracts (D : Class_Diagram; Idx : Class_Index)
                                 return Inherited_Vectors.Vector
   is
      Result : Inherited_Vectors.Vector;
      This_Name : constant String :=
        To_String (D.Pool (Positive (Idx)).Id);

      function Has_Override (Method_Name : String) return Boolean is
      begin
         for M of D.Pool (Positive (Idx)).Members loop
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
         if To_String (R.To) = This_Name
           and then (R.Kind = Inheritance or else R.Kind = Realization)
         then
            declare
               Parent_Pkg : constant String :=
                 Sanitize (To_String (R.From));
            begin
               for P of D.Pool loop
                  if To_String (P.Id) = To_String (R.From) then
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

   function Method_Decls (D : Class_Diagram; Idx : Class_Index)
                          return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        To_String (D.Pool (Positive (Idx)).Id);
      Is_Interface : constant Boolean :=
        D.Pool (Positive (Idx)).Kind = Interface_Kind;
      Is_Abstract_Type : constant Boolean :=
        D.Pool (Positive (Idx)).Kind = Abstract_Class;
   begin
      for M of D.Pool (Positive (Idx)).Members loop
         if M.Kind = Method then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Has_Parent : constant Boolean :=
                 Has_Parent_Method (D, Class_Name, To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean :=
                 Length (M.Type_Name) = 0
                 or else To_String (M.Type_Name) = "void";
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

   function Method_Bodies (D : Class_Diagram; Idx : Class_Index)
                           return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Pool (Positive (Idx)).Id));
   begin
      for M of D.Pool (Positive (Idx)).Members loop
         if M.Kind = Method and then not M.Is_Abstract then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean :=
                 Length (M.Type_Name) = 0
                 or else To_String (M.Type_Name) = "void";
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

   function Actions_Inherited_Decls (D : Class_Diagram; Idx : Class_Index)
                                     return String;
   function Actions_Inherited_Bodies (D : Class_Diagram; Idx : Class_Index)
                                      return String;

   function Actions_Decls (D : Class_Diagram; Idx : Class_Index)
                           return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Pool (Positive (Idx)).Id));
   begin
      for M of D.Pool (Positive (Idx)).Members loop
         if M.Kind = Method and then not M.Is_Abstract then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean :=
                 Length (M.Type_Name) = 0
                 or else To_String (M.Type_Name) = "void";
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
   function Actions_Inherited_Decls (D : Class_Diagram; Idx : Class_Index)
                                     return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Pool (Positive (Idx)).Id));
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

   function Actions_Inherited_Bodies (D : Class_Diagram; Idx : Class_Index)
                                      return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Pool (Positive (Idx)).Id));
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

   function Actions_Bodies (D : Class_Diagram; Idx : Class_Index)
                            return String
   is
      R : Unbounded_String;
      Class_Name : constant String :=
        Sanitize (To_String (D.Pool (Positive (Idx)).Id));
   begin
      for M of D.Pool (Positive (Idx)).Members loop
         if M.Kind = Method and then not M.Is_Abstract then
            declare
               Name : constant String := Sanitize (To_String (M.Id));
               Ret : constant String := Map_Type (To_String (M.Type_Name));
               Is_Proc : constant Boolean :=
                 Length (M.Type_Name) = 0
                 or else To_String (M.Type_Name) = "void";
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

   function With_Clauses (D : Class_Diagram; Idx : Class_Index)
                          return String
   is
      R : Unbounded_String;
      K : constant Classifier := D.Pool (Positive (Idx));
      Parents : constant String :=
        To_String (Parents_Of (D, To_String (K.Id)));
   begin
      if Uses_Unbounded (D, Idx) then
         Append (R, "with Ada.Strings.Unbounded;"
                 & "  use Ada.Strings.Unbounded;" & ASCII.LF);
      end if;
      --  Parents: parse comma/and-separated list; simplest to iterate
      --  relations again to get each parent's package name.
      for Rel of D.Relations loop
         if To_String (Rel.To) = To_String (K.Id)
           and then (Rel.Kind = Inheritance or else Rel.Kind = Realization)
         then
            Append (R, "with " & Sanitize (To_String (Rel.From))
                    & ";" & ASCII.LF);
         end if;
      end loop;
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

   procedure Emit_One (D : Class_Diagram; Idx : Class_Index;
                       Source_Diagram, Date_Str, Out_Dir : String)
   is
      K : constant Classifier := D.Pool (Positive (Idx));
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

      --  Enumeration: spec only, no body
      if K.Kind = Enumeration then
         Insert (T, Assoc ("TYPE_DECL", Type_Decl (D, Idx)));
         Render_To ("class_enum.ads.tmplt", Ads_File, T);
         return;
      end if;

      --  Regular or abstract class
      Insert (T, Assoc ("WITH_CLAUSES", With_Clauses (D, Idx)));
      Insert (T, Assoc ("TYPE_DECL", Type_Decl (D, Idx)));
      Insert (T, Assoc ("METHOD_DECLS", Method_Decls (D, Idx)));
      Render_To ("class.ads.tmplt", Ads_File, T);

      if Has_Methods then
         Insert (T, Assoc ("METHOD_BODIES", Method_Bodies (D, Idx)));
         Render_To ("class.adb.tmplt", Adb_File, T);

         Insert (T, Assoc ("METHOD_DECLS", Actions_Decls (D, Idx)));
         Render_If_Missing ("class_actions.ads.tmplt", Act_Ads, T);

         Insert (T, Assoc ("METHOD_BODIES", Actions_Bodies (D, Idx)));
         Render_If_Missing ("class_actions.adb.tmplt", Act_Adb, T);
      else
         Insert (T, Assoc ("METHOD_BODIES", ""));
         Render_To ("class.adb.tmplt", Adb_File, T);
      end if;
   end Emit_One;

   procedure Generate
     (D              : Class_Diagram;
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

      for I in D.Pool.First_Index .. D.Pool.Last_Index loop
         if D.Pool (I).Kind /= Package_Kind then
            Emit_One (D, Class_Index (I), Source_Diagram,
                      To_String (Date_Str), Out_Dir);
         end if;
      end loop;
   end Generate;

end PlantUML2Code_Ada_Classes;
