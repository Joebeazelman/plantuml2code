--  Ada class-diagram code generation (Phase 2 refactored).
--
--  Language-agnostic orchestrator: walks the UML model, builds
--  dictionaries with raw values, and delegates all formatting
--  (type mapping, identifier casing, keywords) to Jintp templates.

with Ada.Characters.Handling;      use Ada.Characters.Handling;
with Ada.Containers.Vectors;
with Ada.Directories;
with Ada.Strings.Unbounded;       use Ada.Strings.Unbounded;

with UML.Model;
with UML.Model.Queries;            use UML.Model.Queries;
with Uml2Code_Utils;               use Uml2Code_Utils;
with Uml2Code_Filters;
with Uml2Code_Generator_Support;   use Uml2Code_Generator_Support;
with Uml2Code_Ada_Comments;
with Uml2Code_Template_Path;

with Jintp;                        use Jintp;

package body Uml2Code_Ada_Classes is

   use type UML.Model.Element_Kind;
   use type UML.Model.Relation_Kind;
   use type UML.Model.Element_Index;
   use type UML.Model.Element_Index_Vectors.Vector;

   function Id_Of
     (D : UML.Model.Diagram; Idx : UML.Model.Element_Index) return String
   is
   begin
      if Idx = 0 or else Positive (Idx) > Natural (D.Elements.Length) then
         return "";
      end if;
      return To_String (D.Elements (Positive (Idx)).Id);
   end Id_Of;

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String)
   is
      Env : Jintp.Environment;
   begin
      Generate (D, Source_Diagram, Out_Dir, Env);
   end Generate;

   procedure Generate
     (D              : UML.Model.Diagram;
      Source_Diagram : String;
      Out_Dir        : String;
      Env            : in out Jintp.Environment)
   is
      Date_Str : constant String := Today;

      procedure Emit_Package
        (Pkg_Name : String;
         Indices  : UML.Model.Element_Index_Vectors.Vector;
         Out_Dir  : String)
      is
         Dict          : Dictionary;
         Interface_List : List;
         Enum_List     : List;
         Class_List    : List;
      begin
         --  Package-level context (raw values, no formatting)
         Insert (Dict, "PACKAGE_NAME", Pkg_Name);
         Insert (Dict, "GENERATION_DATE", Date_Str);
         Insert (Dict, "SOURCE_DIAGRAM", Source_Diagram);
         Insert (Dict, "TITLE_LINE", Title_Of (D));
         Insert (Dict, "comment_lines",
                 Uml2Code_Ada_Comments.Comment_Lines
                   (Notes_Of (D), Uml2Code_Template_Path.Comment_Wrap));

         --  Build separate lists for each element kind
         for Idx of Indices loop
            if Idx = 0 or else Positive (Idx) > Natural (D.Elements.Length) then
               goto Continue_Element;
            end if;

            declare
               Elem      : UML.Model.Element renames
                 D.Elements (Positive (Idx));
               E_Dict    : Dictionary;
               Attr_List : List;
               Meth_List : List;
               Rel_List  : List;
               Lit_List  : List;
               Has_Fields : Boolean := False;
               Name      : constant String := To_String (Elem.Id);
            begin
               --  Raw identifiers - templates apply filters
               Insert (E_Dict, "name", Name);
               Insert (E_Dict, "kind", Elem.Kind'Image);
               Insert (E_Dict, "is_abstract",
                       Elem.Kind = UML.Model.Abstract_Class);

               declare
                  Comments : Unbounded_String;
               begin
                  for Note of Elem.Notes loop
                     if Length (Comments) > 0 then
                        Append (Comments, ASCII.LF);
                     end if;
                     Append (Comments, Note.Text);
                  end loop;
                  Insert (E_Dict, "comment_lines",
                          Uml2Code_Ada_Comments.Comment_Lines
                            (To_String (Comments),
                             Uml2Code_Template_Path.Comment_Wrap));
               end;

               --  Find parent via inheritance (raw name)
               declare
                  Parent : Unbounded_String;
               begin
                  for R of D.Relations loop
                     if R.Kind = UML.Model.Inheritance
                       and then Id_Of (D, R.To) = Name
                     then
                        Parent := To_Unbounded_String (Id_Of (D, R.From));
                        exit;
                     end if;
                  end loop;
                  Insert (E_Dict, "parent", To_String (Parent));
                  Insert (E_Dict, "has_parent", Length (Parent) > 0);
               end;

               --  Find interfaces via realization
               declare
                  Iface_List  : List;
                  Has_Iface   : Boolean := False;
                  First_Iface : Unbounded_String;
               begin
                  for R of D.Relations loop
                     if R.Kind = UML.Model.Realization
                       and then Id_Of (D, R.To) = Name
                     then
                        Append (Iface_List, Id_Of (D, R.From));
                        if not Has_Iface then
                           First_Iface := To_Unbounded_String
                             (Id_Of (D, R.From));
                           Has_Iface := True;
                        end if;
                     end if;
                  end loop;
                  Insert (E_Dict, "interfaces", Iface_List);
                  Insert (E_Dict, "has_interface", Has_Iface);
                  Insert (E_Dict, "first_interface",
                          To_String (First_Iface));
               end;

               --  Find interfaces via realization (raw names)
               declare
                  Iface_List : List;
               begin
                  for R of D.Relations loop
                     if R.Kind = UML.Model.Realization
                       and then Id_Of (D, R.To) = Name
                     then
                        Append (Iface_List, Id_Of (D, R.From));
                     end if;
                  end loop;
                  Insert (E_Dict, "interfaces", Iface_List);
               end;

               --  Enum literals (raw names)
               if Elem.Kind = UML.Model.Enumeration then
                  for M of Elem.Members loop
                     if M.Kind = UML.Model.Enum_Literal then
                        Append (Lit_List, To_String (M.Id));
                     end if;
                  end loop;
               end if;
               Insert (E_Dict, "literals", Lit_List);

               --  Attributes (raw names and types)
               for M of Elem.Members loop
                  if M.Kind = UML.Model.Attribute then
                     declare
                        A_Dict : Dictionary;
                     begin
                        Insert (A_Dict, "name", To_String (M.Id));
                        Insert (A_Dict, "type", To_String (M.Type_Name));
                        Append (Attr_List, A_Dict);
                        Has_Fields := True;
                     end;
                  end if;
               end loop;
               Insert (E_Dict, "attributes", Attr_List);

               --  Relation-backed fields, rendered as plain lines to keep the
               --  template layout simple and parser-friendly.
               declare
                  Field_Lines : List;
               begin
                  for M of Elem.Members loop
                     if M.Kind = UML.Model.Attribute then
                        Append (Field_Lines,
                                "Attr_" & To_String (M.Id) & " : " &
                                To_String (M.Type_Name) & ";");
                     end if;
                  end loop;

                  for R of D.Relations loop
                     if (R.Kind = UML.Model.Composition
                         or else R.Kind = UML.Model.Association
                         or else R.Kind = UML.Model.Aggregation)
                       and then Id_Of (D, R.From) = Name
                     then
                        declare
                           Target : constant String := Id_Of (D, R.To);
                           Target_Is_Enum : Boolean := False;
                           Line : Unbounded_String;
                        begin
                           for E of D.Elements loop
                              if To_String (E.Id) = Target
                                and then E.Kind = UML.Model.Enumeration
                              then
                                 Target_Is_Enum := True;
                                 exit;
                              end if;
                           end loop;

                           if R.Kind = UML.Model.Composition then
                              Line := To_Unbounded_String
                                ("Attr_" & Target & " : " & Target &
                                 "_Vectors.Vector;");
                           elsif Target_Is_Enum then
                              Line := To_Unbounded_String
                                ("Attr_" & Target & " : " & Target & ";");
                           else
                              Line := To_Unbounded_String
                                ("Attr_" & Target & " : access " & Target & ";");
                           end if;

                           Append (Field_Lines, To_String (Line));
                           Has_Fields := True;
                        end;
                     end if;
                  end loop;

                  Insert (E_Dict, "field_lines", Field_Lines);
               end;

               --  Relations (raw target names and kinds)
               for R of D.Relations loop
                  if (R.Kind = UML.Model.Composition
                      or else R.Kind = UML.Model.Association
                      or else R.Kind = UML.Model.Aggregation)
                    and then Id_Of (D, R.From) = Name
                  then
                     declare
                        R_Dict : Dictionary;
                        Target : constant String := Id_Of (D, R.To);
                        Target_Is_Enum : Boolean := False;
                     begin
                        --  Check if target is an enum
                        for E of D.Elements loop
                           if To_String (E.Id) = Target
                             and then E.Kind = UML.Model.Enumeration
                           then
                              Target_Is_Enum := True;
                              exit;
                           end if;
                        end loop;

                        Insert (R_Dict, "target", Target);
                        Insert (R_Dict, "kind", R.Kind'Image);
                        Insert (R_Dict, "is_composition",
                                R.Kind = UML.Model.Composition);
                        Insert (R_Dict, "is_enum_target", Target_Is_Enum);
                        Append (Rel_List, R_Dict);
                        Has_Fields := True;
                     end;
                  end if;
               end loop;
               Insert (E_Dict, "relations", Rel_List);
               Insert (E_Dict, "has_fields", Has_Fields);

               --  Methods (raw names, types, params)
               for M of Elem.Members loop
                  if M.Kind = UML.Model.Method then
                     declare
                        M_Dict : Dictionary;
                        Ret_Type : constant String := To_String (M.Type_Name);
                     begin
                        Insert (M_Dict, "name", To_String (M.Id));
                        Insert (M_Dict, "return_type", Ret_Type);
                        Insert (M_Dict, "params", To_String (M.Params));
                        Insert (M_Dict, "is_abstract", M.Is_Abstract);
                        Insert (M_Dict, "is_static", M.Is_Static);
                        Insert (M_Dict, "has_return_type",
                                Ret_Type /= "" and then Ret_Type /= "void");
                        Append (Meth_List, M_Dict);
                     end;
                  end if;
               end loop;
               Insert (E_Dict, "methods", Meth_List);

               --  Add to appropriate list based on kind
               if Elem.Kind = UML.Model.Interface_Kind then
                  Append (Interface_List, E_Dict);
               elsif Elem.Kind = UML.Model.Enumeration then
                  Append (Enum_List, E_Dict);
               else
                  Append (Class_List, E_Dict);
               end if;
            end;

            <<Continue_Element>>
         end loop;

         Insert (Dict, "interfaces", Interface_List);
         Insert (Dict, "enums", Enum_List);
         Insert (Dict, "classes", Class_List);

         --  Collect vector instantiations for composition relations
         declare
            Vector_List : List;
            Has_Vector_Instantiations : Boolean := False;
         begin
            for Idx of Indices loop
               if Idx /= 0
                 and then Positive (Idx) <= Natural (D.Elements.Length)
               then
                  declare
                     Elem : UML.Model.Element renames
                       D.Elements (Positive (Idx));
                     EName : constant String := To_String (Elem.Id);
                  begin
                     for R of D.Relations loop
                        if R.Kind = UML.Model.Composition
                          and then Id_Of (D, R.From) = EName
                        then
                           declare
                              V_Dict : Dictionary;
                              Target : constant String :=
                                Id_Of (D, R.To);
                           begin
                              Insert (V_Dict, "element_type", Target);
                              Insert (V_Dict, "vector_name",
                                      Target & "_Vectors");
                              Append (Vector_List, V_Dict);
                              Has_Vector_Instantiations := True;
                           end;
                        end if;
                     end loop;
                  end;
               end if;
            end loop;
            Insert (Dict, "vector_instantiations", Vector_List);
            Insert (Dict, "has_vector_instantiations",
                    Has_Vector_Instantiations);
         end;

         --  Track if we need Unbounded_String
         declare
            Needs_Unbounded : Boolean := False;
         begin
            for Idx of Indices loop
               if Idx /= 0
                 and then Positive (Idx) <= Natural (D.Elements.Length)
               then
                  declare
                     Elem : UML.Model.Element renames
                       D.Elements (Positive (Idx));
                  begin
                     for M of Elem.Members loop
                        if M.Kind = UML.Model.Attribute
                          or else M.Kind = UML.Model.Method
                        then
                           declare
                              T : constant String :=
                                To_Lower (To_String (M.Type_Name));
                           begin
                              if T = "string" or else T = "str" then
                                 Needs_Unbounded := True;
                                 exit;
                              end if;
                           end;
                        end if;
                     end loop;
                     if Needs_Unbounded then
                        exit;
                     end if;
                  end;
               end if;
            end loop;
            Insert (Dict, "needs_unbounded", Needs_Unbounded);
         end;

         --  Render templates
         Render_To_Dict
           ("ada/class", "class.ads.tmplt",
            Ada.Directories.Compose (Out_Dir, Pkg_Name & ".ads"),
            Dict, Env);

         Render_To_Dict
           ("ada/class", "class.adb.tmplt",
            Ada.Directories.Compose (Out_Dir, Pkg_Name & ".adb"),
            Dict, Env);

      end Emit_Package;

   begin
      Uml2Code_Filters.Register_Filters (Env);
      Refuse_Crate_Internal_Output (Out_Dir);
      declare
         Src_Dir : constant String :=
           Ada.Directories.Compose (Out_Dir, "src");
      begin
         Ada.Directories.Create_Path (Src_Dir);

         --  Group elements by package and emit each
         declare
            type Pkg_Info is record
               Name    : Unbounded_String;
               Indices : UML.Model.Element_Index_Vectors.Vector;
            end record;

            package Pkg_Vectors is new Ada.Containers.Vectors
              (Positive, Pkg_Info);

            Packages : Pkg_Vectors.Vector;
         begin
            for I in 1 .. Natural (D.Elements.Length) loop
               declare
                  Elem     : UML.Model.Element renames D.Elements (I);
                  Pkg_Name : constant String :=
                    (if Elem.Parent = 0 then "Model"
                     else Id_Of (D, Elem.Parent));
                  Found    : Boolean := False;
               begin
                  --  Skip package elements themselves
                  if Elem.Kind = UML.Model.Package_Kind then
                     goto Continue_Elem;
                  end if;

                  for P in Packages.First_Index .. Packages.Last_Index loop
                     if To_String (Packages (P).Name) = Pkg_Name then
                        Packages (P).Indices.Append
                          (UML.Model.Element_Index (I));
                        Found := True;
                        exit;
                     end if;
                  end loop;

                  if not Found then
                     declare
                        New_Pkg : Pkg_Info;
                     begin
                        New_Pkg.Name := To_Unbounded_String (Pkg_Name);
                        New_Pkg.Indices.Append (UML.Model.Element_Index (I));
                        Packages.Append (New_Pkg);
                     end;
                  end if;
               end;

               <<Continue_Elem>>
            end loop;

            for P in Packages.First_Index .. Packages.Last_Index loop
               Emit_Package (To_String (Packages (P).Name),
                             Packages (P).Indices,
                             Src_Dir);
            end loop;
         end;
      end;
   end Generate;

end Uml2Code_Ada_Classes;
