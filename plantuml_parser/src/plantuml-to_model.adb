with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;

package body PlantUML.To_Model is

   use type PlantUML.States.Annotation_Kind;
   use type PlantUML.Classes.Annotation_Kind;

   --  ---------------------------------------------------------------
   --  Enumeration mappings
   --  ---------------------------------------------------------------

   function State_Kind_To_Element
     (K : PlantUML.States.State_Kind) return UML.Model.Element_Kind
   is
   begin
      case K is
         when PlantUML.States.Simple =>
            return UML.Model.Simple_State;
         when PlantUML.States.Composite =>
            return UML.Model.Composite_State;
         when PlantUML.States.Submachine_Reference =>
            return UML.Model.Submachine_Reference;
         when PlantUML.States.Start_Pseudostate =>
            return UML.Model.Start_Pseudostate;
         when PlantUML.States.End_Pseudostate =>
            return UML.Model.End_Pseudostate;
         when PlantUML.States.Choice_Pseudostate =>
            return UML.Model.Choice;
         when PlantUML.States.Fork_Pseudostate =>
            return UML.Model.Fork;
         when PlantUML.States.Join_Pseudostate =>
            return UML.Model.Join;
         when PlantUML.States.History_Shallow =>
            return UML.Model.History_Shallow;
         when PlantUML.States.History_Deep =>
            return UML.Model.History_Deep;
         when PlantUML.States.Entry_Point =>
            return UML.Model.Entry_Point;
         when PlantUML.States.Exit_Point =>
            return UML.Model.Exit_Point;
      end case;
   end State_Kind_To_Element;

   function Annotation_Kind_To_Model
     (K : PlantUML.States.Annotation_Kind)
      return UML.Model.Annotation_Kind
   is
   begin
      case K is
         when PlantUML.States.Entry_Action =>
            return UML.Model.Entry_Action;
         when PlantUML.States.Exit_Action =>
            return UML.Model.Exit_Action;
         when PlantUML.States.Do_Activity =>
            return UML.Model.Do_Activity;
         when PlantUML.States.Internal_Transition =>
            return UML.Model.Internal_Transition;
         when PlantUML.States.Note =>
            return UML.Model.Other;
         when PlantUML.States.Stereotype =>
            return UML.Model.Stereotype;
         when PlantUML.States.Unknown =>
            return UML.Model.Other;
      end case;
   end Annotation_Kind_To_Model;

   function Transition_Kind_To_Relation
     (K : PlantUML.States.Transition_Kind)
      return UML.Model.Relation_Kind
   is
   begin
      case K is
         when PlantUML.States.External =>
            return UML.Model.Transition;
         when PlantUML.States.Internal =>
            return UML.Model.Internal_Transition_Kind;
         when PlantUML.States.Local =>
            return UML.Model.Transition;
         when PlantUML.States.Completion =>
            return UML.Model.Completion;
      end case;
   end Transition_Kind_To_Relation;

   function Class_Kind_To_Element
     (K : PlantUML.Classes.Classifier_Kind)
      return UML.Model.Element_Kind
   is
   begin
      case K is
         when PlantUML.Classes.Class =>
            return UML.Model.Class;
         when PlantUML.Classes.Abstract_Class =>
            return UML.Model.Abstract_Class;
         when PlantUML.Classes.Interface_Kind =>
            return UML.Model.Interface_Kind;
         when PlantUML.Classes.Enumeration =>
            return UML.Model.Enumeration;
         when PlantUML.Classes.Record_Type =>
            return UML.Model.Record_Type;
         when PlantUML.Classes.Annotation_Def =>
            return UML.Model.Annotation_Type;
         when PlantUML.Classes.Stereotype_Def =>
            return UML.Model.Annotation_Type;
         when PlantUML.Classes.Package_Kind =>
            return UML.Model.Package_Kind;
         when PlantUML.Classes.Object =>
            return UML.Model.Object;
      end case;
   end Class_Kind_To_Element;

   function Class_Relation_To_Relation
     (K : PlantUML.Classes.Relation_Kind)
      return UML.Model.Relation_Kind
   is
   begin
      case K is
         when PlantUML.Classes.Inheritance =>
            return UML.Model.Inheritance;
         when PlantUML.Classes.Realization =>
            return UML.Model.Realization;
         when PlantUML.Classes.Composition =>
            return UML.Model.Composition;
         when PlantUML.Classes.Aggregation =>
            return UML.Model.Aggregation;
         when PlantUML.Classes.Association =>
            return UML.Model.Association;
         when PlantUML.Classes.Dependency =>
            return UML.Model.Dependency;
         when PlantUML.Classes.Link =>
            return UML.Model.Link;
      end case;
   end Class_Relation_To_Relation;

   --  ---------------------------------------------------------------
   --  Name lookup
   --  ---------------------------------------------------------------

   function Index_Of (D : UML.Model.Diagram; Name : String)
                      return UML.Model.Element_Index
   is
   begin
      for I in D.Elements.First_Index .. D.Elements.Last_Index loop
         if To_String (D.Elements (I).Id) = Name then
            return UML.Model.Element_Index (I);
         end if;
      end loop;
      return UML.Model.Element_Index (0);
   end Index_Of;

   --  ---------------------------------------------------------------
   --  States
   --  ---------------------------------------------------------------

   function From_State (D : PlantUML.States.State_Diagram)
                        return UML.Model.Diagram
   is
      Result : UML.Model.Diagram;
   begin
      Result.Kind := UML.Model.State_Diagram;
      Result.Id   := D.Diagram_Name;

      if Length (D.Title) > 0 then
         Result.Metadata.Append
           (UML.Model.Metadata'(Kind => UML.Model.Title,
                                Text => D.Title));
      end if;

      for S of D.Pool loop
         declare
            E : UML.Model.Element;
         begin
            E.Id      := S.Id;
            E.Display := S.Display;
            E.Kind    := State_Kind_To_Element (S.Kind);

            for A of S.Annotations loop
               if A.Kind = PlantUML.States.Note then
                  --  Notes are separate from action annotations.
                  E.Notes.Append
                    (UML.Model.Note'(Text     => A.Action,
                                     Subject  => 0,
                                     Position => UML.Model.Attached));
               else
                  E.Annotations.Append
                    (UML.Model.Annotation'
                       (Kind    => Annotation_Kind_To_Model (A.Kind),
                        Text    => A.Action,
                        Trigger => A.Trigger,
                        Guard   => A.Guard));
               end if;
            end loop;

            for C of S.Children loop
               E.Children.Append (UML.Model.Element_Index (C));
            end loop;

            Result.Elements.Append (E);
         end;
      end loop;

      for R of D.Roots loop
         Result.Roots.Append (UML.Model.Element_Index (R));
      end loop;

      for T of D.Transitions loop
         declare
            Rel : UML.Model.Relation;
         begin
            Rel.From    := Index_Of (Result, To_String (T.From));
            Rel.To      := Index_Of (Result, To_String (T.To));
            Rel.Kind    := Transition_Kind_To_Relation (T.Kind);
            Rel.Trigger := T.Trigger;
            Rel.Guard   := T.Guard;
            Rel.Effect  := T.Effect;
            Rel.Label   := T.Label;
            Result.Relations.Append (Rel);
         end;
      end loop;

      return Result;
   end From_State;

   --  ---------------------------------------------------------------
   --  Classes
   --  ---------------------------------------------------------------

   function From_Classes (D : PlantUML.Classes.Class_Diagram)
                          return UML.Model.Diagram
   is
      Result : UML.Model.Diagram;
   begin
      Result.Kind := UML.Model.Class_Diagram;
      Result.Id   := D.Diagram_Name;

      if Length (D.Title) > 0 then
         Result.Metadata.Append
           (UML.Model.Metadata'(Kind => UML.Model.Title,
                                Text => D.Title));
      end if;

      for K of D.Pool loop
         declare
            E : UML.Model.Element;
         begin
            E.Id      := K.Id;
            E.Display := K.Display;
            E.Kind    := Class_Kind_To_Element (K.Kind);

            for M of K.Members loop
               E.Members.Append
                 (UML.Model.Member'
                    (Kind        =>
                     (case M.Kind is
                         when PlantUML.Classes.Attribute =>
                            UML.Model.Attribute,
                         when PlantUML.Classes.Method =>
                            UML.Model.Method,
                         when PlantUML.Classes.Enum_Literal =>
                            UML.Model.Enum_Literal,
                         when PlantUML.Classes.Nested_Class =>
                            UML.Model.Nested_Class),
                   Id          => M.Id,
                   Type_Name   => M.Type_Name,
                   Params      => M.Params,
                   Vis         =>
                     (case M.Vis is
                         when PlantUML.Classes.Public_Vis =>
                            UML.Model.Public_Vis,
                         when PlantUML.Classes.Private_Vis =>
                            UML.Model.Private_Vis,
                         when PlantUML.Classes.Protected_Vis =>
                            UML.Model.Protected_Vis,
                         when PlantUML.Classes.Package_Level =>
                            UML.Model.Package_Vis),
                     Is_Static   => M.Is_Static,
                     Is_Abstract => M.Is_Abstract,
                     Annotations => <>));
            end loop;

            --  Classifier annotations: Notes go to E.Notes, others
            --  to E.Annotations.
            for A of K.Annotations loop
               if A.Kind = PlantUML.Classes.Note then
                  E.Notes.Append
                    (UML.Model.Note'
                       (Text     => A.Text,
                        Subject  => 0,
                        Position =>
                          (case A.Position is
                              when PlantUML.Classes.Attached  =>
                                 UML.Model.Attached,
                              when PlantUML.Classes.Right_Of  =>
                                 UML.Model.Right_Of,
                              when PlantUML.Classes.Left_Of   =>
                                 UML.Model.Left_Of,
                              when PlantUML.Classes.Top_Of    =>
                                 UML.Model.Top_Of,
                              when PlantUML.Classes.Bottom_Of =>
                                 UML.Model.Bottom_Of)));
               else
                  E.Annotations.Append
                    (UML.Model.Annotation'
                       (Kind    =>
                          (case A.Kind is
                              when PlantUML.Classes.Stereotype =>
                                 UML.Model.Stereotype,
                              when PlantUML.Classes.Tag =>
                                 UML.Model.Tag,
                              when others =>
                                 UML.Model.Other),
                        Text    => A.Text,
                        Trigger => Null_Unbounded_String,
                        Guard   => Null_Unbounded_String));
               end if;
            end loop;

            for C of K.Children loop
               E.Children.Append (UML.Model.Element_Index (C));
            end loop;

            Result.Elements.Append (E);
         end;
      end loop;

      --  Diagram-level notes.
      for N of D.Notes loop
         Result.Notes.Append
           (UML.Model.Note'
              (Text     => N.Text,
               Subject  => 0,
               Position =>
                 (case N.Position is
                     when PlantUML.Classes.Attached  =>
                        UML.Model.Attached,
                     when PlantUML.Classes.Right_Of  =>
                        UML.Model.Right_Of,
                     when PlantUML.Classes.Left_Of   =>
                        UML.Model.Left_Of,
                     when PlantUML.Classes.Top_Of    =>
                        UML.Model.Top_Of,
                     when PlantUML.Classes.Bottom_Of =>
                        UML.Model.Bottom_Of)));
      end loop;

      for R of D.Roots loop
         Result.Roots.Append (UML.Model.Element_Index (R));
      end loop;

      for Rel of D.Relations loop
         declare
            R : UML.Model.Relation;
         begin
            R.From      := Index_Of (Result, To_String (Rel.From));
            R.To        := Index_Of (Result, To_String (Rel.To));
            R.Kind      := Class_Relation_To_Relation (Rel.Kind);
            R.Label     := Rel.Label;
            R.Mult_From := Rel.Mult_From;
            R.Mult_To   := Rel.Mult_To;
            Result.Relations.Append (R);
         end;
      end loop;

      --  Reverse-populate Parent from Children. The parser records
      --  containment via Children (package -> member); the generator
      --  needs the reverse to walk upwards.
      for I in Result.Elements.First_Index .. Result.Elements.Last_Index loop
         for C of Result.Elements (I).Children loop
            declare
               Child : UML.Model.Element :=
                 Result.Elements (Positive (C));
            begin
               Child.Parent := UML.Model.Element_Index (I);
               Result.Elements.Replace_Element (Positive (C), Child);
            end;
         end loop;
      end loop;

      return Result;
   end From_Classes;

end PlantUML.To_Model;
