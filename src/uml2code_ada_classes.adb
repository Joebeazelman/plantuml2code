with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Directories;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with Ada.Characters.Handling;

with UML.Model;
with Uml2Code_Utils;

package body Uml2Code_Ada_Classes is

   use type UML.Model.Element_Kind;
   use type UML.Model.Element_Index;
   use type UML.Model.Relation_Kind;

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String)
   is
      type Index_Array is array (Positive range <>) of UML.Model.Element_Index;
      Src_Dir : constant String := Ada.Directories.Compose (Out_Dir, "src");

      function Id_Of (Idx : UML.Model.Element_Index) return String is
      begin
         if Idx = 0 or else Positive (Idx) > Natural (D.Elements.Length) then
            return "";
         end if;
         return To_String (D.Elements (Positive (Idx)).Id);
      end Id_Of;

      function Map_Type (Uml_Type : String) return String is
      begin
         if Uml_Type = "" then return "";
         elsif Uml_Type = "String" then return "Unbounded_String";
         elsif Uml_Type = "Integer" then return "Integer";
         elsif Uml_Type = "Boolean" then return "Boolean";
         elsif Uml_Type = "void" then return "";
         else return Uml_Type;
         end if;
      end Map_Type;

      function Capitalize (S : String) return String is
      begin
         if S'Length = 0 then return S; end if;
         return (1 => Ada.Characters.Handling.To_Upper (S (S'First))) & S (S'First + 1 .. S'Last);
      end Capitalize;

      function Find_Parent (Class_Name : String) return String is
      begin
         for R of D.Relations loop
            if R.Kind = UML.Model.Inheritance and then Id_Of (R.To) = Class_Name then
               return Id_Of (R.From);
            end if;
         end loop;
         return "";
      end Find_Parent;

      function Find_Interfaces (Class_Name : String) return String is
         Result : Unbounded_String;
         First  : Boolean := True;
      begin
         for R of D.Relations loop
            if R.Kind = UML.Model.Realization and then Id_Of (R.To) = Class_Name then
               if not First then Append (Result, " and "); end if;
               Append (Result, Id_Of (R.From));
               First := False;
            end if;
         end loop;
         return To_String (Result);
      end Find_Interfaces;

      procedure Generate_Package (Pkg_Name : String; Indices : Index_Array) is
         Classes    : Index_Array (1 .. Indices'Length);
         Interfaces : Index_Array (1 .. Indices'Length);
         Enums      : Index_Array (1 .. Indices'Length);
         N_Class    : Natural := 0;
         N_Iface    : Natural := 0;
         N_Enum     : Natural := 0;

         Ads_File : constant String := Ada.Directories.Compose (Src_Dir, Pkg_Name & ".ads");
         F : Ada.Text_IO.File_Type;
      begin
         -- Categorize elements
         for I in Indices'Range loop
            if Indices (I) /= 0 then
               declare
                  Elem : UML.Model.Element renames D.Elements (Positive (Indices (I)));
               begin
                  case Elem.Kind is
                     when UML.Model.Class | UML.Model.Abstract_Class =>
                        N_Class := N_Class + 1; Classes (N_Class) := Indices (I);
                     when UML.Model.Interface_Kind =>
                        N_Iface := N_Iface + 1; Interfaces (N_Iface) := Indices (I);
                     when UML.Model.Enumeration =>
                        N_Enum := N_Enum + 1; Enums (N_Enum) := Indices (I);
                     when others => null;
                  end case;
               end;
            end if;
         end loop;

         Ada.Text_IO.Create (F, Ada.Text_IO.Out_File, Ads_File);
         Ada.Text_IO.Put_Line (F, f"---------------------------------------------------------------------");
         Ada.Text_IO.Put_Line (F, f"--  {Pkg_Name}");
         
         -- Diagram notes
         if Pkg_Name = To_String (D.Id) then
            declare
               Has_Notes : Boolean := False;
            begin
               for N of D.Notes loop
                  if N.Subject = 0 then
                     if not Has_Notes then
                        Ada.Text_IO.Put_Line (F, "--");
                        Ada.Text_IO.Put_Line (F, "--  Notes:");
                        Has_Notes := True;
                     end if;
                     declare
                        Note_Text : constant String := To_String (N.Text);
                     begin
                        Ada.Text_IO.Put (F, "--    ");
                        for I in Note_Text'Range loop
                           if Note_Text (I) = ASCII.LF then
                              Ada.Text_IO.New_Line (F);
                              Ada.Text_IO.Put (F, "--    ");
                           else
                              Ada.Text_IO.Put (F, Note_Text (I));
                           end if;
                        end loop;
                        Ada.Text_IO.New_Line (F);
                     end;
                  end if;
               end loop;
            end;
         end if;
         
         Ada.Text_IO.Put_Line (F, f"---------------------------------------------------------------------\n");

         -- With clauses
         declare
            Needs_Unbounded : Boolean := False;
            Needs_Vectors : Boolean := False;
            Parent_Pkg : constant String := To_String (D.Id);
         begin
            if Pkg_Name /= Parent_Pkg and then Parent_Pkg /= "" then
               Ada.Text_IO.Put_Line (F, f"with {Parent_Pkg};  use {Parent_Pkg};");
            end if;

            for I in Indices'Range loop
               if Indices (I) /= 0 then
                  declare
                     Elem : UML.Model.Element renames D.Elements (Positive (Indices (I)));
                  begin
                     for M of Elem.Members loop
                        if M.Kind = UML.Model.Attribute and then Map_Type (To_String (M.Type_Name)) = "Unbounded_String" then
                           Needs_Unbounded := True;
                        end if;
                     end loop;
                  end;
               end if;
            end loop;

            for I in Indices'Range loop
               if Indices (I) /= 0 then
                  declare
                     Elem : UML.Model.Element renames D.Elements (Positive (Indices (I)));
                     Name : constant String := To_String (Elem.Id);
                  begin
                     for R of D.Relations loop
                        if R.Kind = UML.Model.Composition and then Id_Of (R.From) = Name then
                           Needs_Vectors := True; exit;
                        end if;
                     end loop;
                  end;
               end if;
            end loop;

            if Needs_Unbounded then
               Ada.Text_IO.Put_Line (F, "with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;");
            end if;
            if Needs_Vectors then
               Ada.Text_IO.Put_Line (F, "with Ada.Containers.Vectors;");
            end if;
            if Needs_Unbounded or Needs_Vectors then
               Ada.Text_IO.New_Line (F);
            end if;
         end;

         Ada.Text_IO.Put_Line (F, f"package {Pkg_Name} is\n");

         -- Enums
         for E in 1 .. N_Enum loop
            declare
               Elem : UML.Model.Element renames D.Elements (Positive (Enums (E)));
               Name : constant String := To_String (Elem.Id);
               First_Lit : Boolean := True;
               Lit_Str : Unbounded_String;
            begin
               for M of Elem.Members loop
                  if M.Kind = UML.Model.Enum_Literal then
                     if not First_Lit then Append (Lit_Str, ", "); end if;
                     Append (Lit_Str, To_String (M.Id));
                     First_Lit := False;
                  end if;
               end loop;
               Ada.Text_IO.Put_Line (F, f"   type {Name} is ({To_String (Lit_Str)});\n");
            end;
         end loop;

         -- Vector types for compositions
         for C in 1 .. N_Class loop
            declare
               Elem : UML.Model.Element renames D.Elements (Positive (Classes (C)));
               Name : constant String := To_String (Elem.Id);
            begin
               for R of D.Relations loop
                  if R.Kind = UML.Model.Composition and then Id_Of (R.From) = Name then
                     declare
                        Target : constant String := Id_Of (R.To);
                     begin
                        Ada.Text_IO.Put_Line (F, f"   type {Target}_Access is access all {Target}'Class;\n");
                        Ada.Text_IO.Put_Line (F, f"   package {Target}_Vectors is new Ada.Containers.Vectors");
                        Ada.Text_IO.Put_Line (F, f"     (Index_Type   => Positive,");
                        Ada.Text_IO.Put_Line (F, f"      Element_Type => {Target}_Access);\n");
                     end;
                  end if;
               end loop;
            end;
         end loop;

         -- Interfaces
         for I in 1 .. N_Iface loop
            declare
               Elem : UML.Model.Element renames D.Elements (Positive (Interfaces (I)));
               Name : constant String := To_String (Elem.Id);
            begin
               Ada.Text_IO.Put_Line (F, f"   type {Name} is limited interface;\n");
               for M of Elem.Members loop
                  if M.Kind = UML.Model.Method then
                     declare
                        Method_Name : constant String := To_String (M.Id);
                        Return_Type : constant String := Map_Type (To_String (M.Type_Name));
                     begin
                        if Return_Type /= "" then
                           Ada.Text_IO.Put_Line (F, f"   function {Method_Name} (Self : in out {Name}) return {Return_Type} is abstract;");
                        else
                           Ada.Text_IO.Put_Line (F, f"   procedure {Method_Name} (Self : in out {Name}) is abstract;");
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end loop;
         Ada.Text_IO.New_Line (F);

         -- Classes
         for C in 1 .. N_Class loop
            declare
               Elem : UML.Model.Element renames D.Elements (Positive (Classes (C)));
               Name : constant String := To_String (Elem.Id);
               Parent : constant String := Find_Parent (Name);
               Ifaces : constant String := Find_Interfaces (Name);
               Is_Abstract : constant Boolean := Elem.Kind = UML.Model.Abstract_Class;
            begin
               if C > 1 then Ada.Text_IO.New_Line (F); end if;

               -- Class declaration
               if Is_Abstract then
                  Ada.Text_IO.Put (F, f"   type {Name} is abstract tagged");
               elsif Parent /= "" then
                  if Ifaces /= "" then
                     Ada.Text_IO.Put (F, f"   type {Name} is new {Parent} and {Ifaces} with");
                  else
                     Ada.Text_IO.Put (F, f"   type {Name} is new {Parent} with");
                  end if;
               else
                  Ada.Text_IO.Put (F, f"   type {Name} is tagged");
               end if;

               -- Attributes
               declare
                  Has_Attributes : Boolean := False;
               begin
                  for M of Elem.Members loop
                     if M.Kind = UML.Model.Attribute then Has_Attributes := True; exit; end if;
                  end loop;
                  for R of D.Relations loop
                     if (R.Kind = UML.Model.Composition or R.Kind = UML.Model.Association) and then Id_Of (R.From) = Name then
                        Has_Attributes := True; exit;
                     end if;
                  end loop;

                  if Has_Attributes then
                     Ada.Text_IO.Put_Line (F, " record");
                     for M of Elem.Members loop
                        if M.Kind = UML.Model.Attribute then
                           declare
                              Attr_Name : constant String := Capitalize (To_String (M.Id));
                              Attr_Type : constant String := Map_Type (To_String (M.Type_Name));
                           begin
                              Ada.Text_IO.Put_Line (F, f"      Attr_{Attr_Name} : {Attr_Type};");
                           end;
                        end if;
                     end loop;
                     for R of D.Relations loop
                        if (R.Kind = UML.Model.Composition or R.Kind = UML.Model.Association) and then Id_Of (R.From) = Name then
                           declare
                              Target : constant String := Id_Of (R.To);
                              Target_Is_Enum : Boolean := False;
                           begin
                              for E of D.Elements loop
                                 if To_String (E.Id) = Target and then E.Kind = UML.Model.Enumeration then
                                    Target_Is_Enum := True; exit;
                                 end if;
                              end loop;

                              if R.Kind = UML.Model.Composition then
                                 Ada.Text_IO.Put_Line (F, f"      Attr_{Target} : {Target}_Vectors.Vector;");
                              elsif Target_Is_Enum then
                                 Ada.Text_IO.Put_Line (F, f"      Attr_{Target} : {Target};");
                              else
                                 Ada.Text_IO.Put_Line (F, f"      Attr_{Target} : access {Target};");
                              end if;
                           end;
                        end if;
                     end loop;
                     Ada.Text_IO.Put_Line (F, "   end record;");
                  else
                     Ada.Text_IO.Put_Line (F, " null record;");
                  end if;
               end;
               Ada.Text_IO.New_Line (F);

               -- Methods
               for M of Elem.Members loop
                  if M.Kind = UML.Model.Method then
                     declare
                        Method_Name : constant String := To_String (M.Id);
                        Return_Type : constant String := Map_Type (To_String (M.Type_Name));
                        Is_Overriding : Boolean := False;
                     begin
                        -- Check overriding
                        if Parent /= "" then
                           for P_Elem of D.Elements loop
                              if To_String (P_Elem.Id) = Parent then
                                 for P_M of P_Elem.Members loop
                                    if P_M.Kind = UML.Model.Method and then To_String (P_M.Id) = Method_Name then
                                       Is_Overriding := True; exit;
                                    end if;
                                 end loop;
                                 exit;
                              end if;
                           end loop;
                        end if;

                        if not Is_Overriding and then Ifaces /= "" then
                           declare
                              Iface_List : constant String := Ifaces;
                              Pos : Natural := Iface_List'First;
                           begin
                              while Pos <= Iface_List'Last loop
                                 declare
                                    End_Pos : Natural := Pos;
                                    Iface_Name : Unbounded_String;
                                 begin
                                    while End_Pos <= Iface_List'Last and then Iface_List (End_Pos) /= ' ' loop
                                       End_Pos := End_Pos + 1;
                                    end loop;
                                    Iface_Name := To_Unbounded_String (Iface_List (Pos .. End_Pos - 1));

                                    for I_Elem of D.Elements loop
                                       if To_String (I_Elem.Id) = To_String (Iface_Name) and then I_Elem.Kind = UML.Model.Interface_Kind then
                                          for I_M of I_Elem.Members loop
                                             if I_M.Kind = UML.Model.Method and then To_String (I_M.Id) = Method_Name then
                                                Is_Overriding := True; exit;
                                             end if;
                                          end loop;
                                          exit when Is_Overriding;
                                       end if;
                                    end loop;

                                    Pos := End_Pos;
                                    while Pos <= Iface_List'Last and then (Iface_List (Pos) = ' ' or else Iface_List (Pos .. Pos + 3) = "and ") loop
                                       if Iface_List (Pos .. Pos + 3) = "and " then Pos := Pos + 4;
                                       else Pos := Pos + 1; end if;
                                    end loop;
                                 end;
                                 exit when Is_Overriding;
                              end loop;
                           end;
                        end if;

                        if Is_Overriding then
                           Ada.Text_IO.Put_Line (F, "   overriding");
                        end if;

                        if M.Is_Abstract then
                           if Return_Type /= "" then
                              Ada.Text_IO.Put_Line (F, f"   function {Method_Name} (Self : in out {Name}) return {Return_Type} is abstract;");
                           else
                              Ada.Text_IO.Put_Line (F, f"   procedure {Method_Name} (Self : in out {Name}) is abstract;");
                           end if;
                        else
                           if Return_Type /= "" then
                              Ada.Text_IO.Put_Line (F, f"   function {Method_Name} (Self : in out {Name}) return {Return_Type};");
                           else
                              Ada.Text_IO.Put_Line (F, f"   procedure {Method_Name} (Self : in out {Name});");
                           end if;
                        end if;
                     end;
                  end if;
               end loop;
            end;
         end loop;

         Ada.Text_IO.Put_Line (F, f"\nend {Pkg_Name};");
         Ada.Text_IO.Close (F);
         Put_Line (f"wrote {Ads_File}");
      end Generate_Package;

      Top_Last  : Natural := 0;
      Pkg_Last  : Natural := 0;
      Top_Elements : Index_Array (1 .. 1000);
      Pkg_Elements : Index_Array (1 .. 1000);

   begin
      Ada.Directories.Create_Path (Src_Dir);

      for I in 1 .. Natural (D.Elements.Length) loop
         declare
            Elem : UML.Model.Element renames D.Elements (I);
            Is_Child : Boolean := False;
         begin
            for J in 1 .. Natural (D.Elements.Length) loop
               for C of D.Elements (J).Children loop
                  if Positive (C) = I then Is_Child := True; exit; end if;
               end loop;
               exit when Is_Child;
            end loop;

            if not Is_Child then
               if Elem.Kind = UML.Model.Package_Kind then
                  Pkg_Last := Pkg_Last + 1;
                  Pkg_Elements (Pkg_Last) := UML.Model.Element_Index (I);
               else
                  Top_Last := Top_Last + 1;
                  Top_Elements (Top_Last) := UML.Model.Element_Index (I);
               end if;
            end if;
         end;
      end loop;

      if Top_Last > 0 then
         declare
            Root_Name : constant String := To_String (D.Id);
         begin
            if Root_Name = "" then
               Generate_Package ("Model", Top_Elements (1 .. Top_Last));
            else
               Generate_Package (Root_Name, Top_Elements (1 .. Top_Last));
            end if;
         end;
      end if;

      for P in 1 .. Pkg_Last loop
         declare
            Pkg_Idx : constant UML.Model.Element_Index := Pkg_Elements (P);
            Pkg_Name : constant String := Id_Of (Pkg_Idx);
            Pkg_Elem : UML.Model.Element renames D.Elements (Positive (Pkg_Idx));
         begin
            if not Pkg_Elem.Children.Is_Empty then
               declare
                  Child_Indices : Index_Array (1 .. Natural (Pkg_Elem.Children.Length));
                  I : Positive := 1;
               begin
                  for C of Pkg_Elem.Children loop
                     Child_Indices (I) := C; I := I + 1;
                  end loop;
                  Generate_Package (Pkg_Name, Child_Indices);
               end;
            end if;
         end;
      end loop;
   end Generate;

end Uml2Code_Ada_Classes;
