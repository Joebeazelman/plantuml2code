--  Normalized internal representation of a UML diagram.
--
--  Types only. Parsers produce UML.Model.Diagram values; generators
--  consume them. Neither knows about the other.
--
--  Every detail a parser can extract has a home here. Translation
--  from a source format into this model must not throw information
--  away; if a construct cannot be represented, the model is wrong,
--  not the parser.

with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package UML.Model is
   pragma Preelaborate;

   subtype Name is Unbounded_String;

   package Name_Vectors is new Ada.Containers.Vectors
     (Positive, Name);

   --  ---------------------------------------------------------------
   --  Diagram kinds
   --  ---------------------------------------------------------------

   type Diagram_Kind is
     (Unknown, State_Diagram, Class_Diagram, Activity_Diagram);

   --  ---------------------------------------------------------------
   --  Element kinds
   --  ---------------------------------------------------------------

   type Element_Kind is
     --  Structural
     (State, Simple_State, Composite_State, Submachine_Reference,
      Class, Abstract_Class, Interface_Kind, Enumeration, Record_Type,
      Annotation_Type, Object, Package_Kind,

      --  Pseudostates
      Start_Pseudostate, End_Pseudostate, Choice, Fork, Join,
      History_Shallow, History_Deep, Entry_Point, Exit_Point,

      --  Class members
      Attribute, Method, Enum_Literal, Nested_Class,

      --  Diagram-level
      Note_Element);

   --  ---------------------------------------------------------------
   --  Annotations on states
   --  ---------------------------------------------------------------

   type Annotation_Kind is
     (Entry_Action, Exit_Action, Do_Activity, Internal_Transition,
      Stereotype, Tag, Other);

   type Annotation is record
      Kind    : Annotation_Kind := Other;
      Text    : Name;
      Trigger : Name;
      Guard   : Name;
   end record;

   package Annotation_Vectors is new Ada.Containers.Vectors
     (Positive, Annotation);

   --  ---------------------------------------------------------------
   --  Notes and comments
   --  ---------------------------------------------------------------

   type Note_Position is (Attached, Left_Of, Right_Of, Top_Of, Bottom_Of);

   --  Indices into Diagram.Elements. 0 means "no subject".
   type Element_Index is new Natural;

   type Note is record
      Text     : Name;
      Subject  : Element_Index := 0;
      Position : Note_Position := Attached;
   end record;

   package Note_Vectors is new Ada.Containers.Vectors (Positive, Note);

   --  ---------------------------------------------------------------
   --  Diagram metadata (title, theme, includes, etc.)
   --  ---------------------------------------------------------------

   type Metadata_Kind is
     (Title, Theme, Include, Directive, Other);

   type Metadata is record
      Kind : Metadata_Kind := Other;
      Text : Name;
   end record;

   package Metadata_Vectors is new Ada.Containers.Vectors
     (Positive, Metadata);

   --  ---------------------------------------------------------------
   --  Class members
   --  ---------------------------------------------------------------

   type Visibility is
     (Public_Vis, Private_Vis, Protected_Vis, Package_Vis);

   type Member is record
      Kind        : Element_Kind := Attribute;
      Id          : Name;
      Type_Name   : Name;
      Params      : Name;
      Vis         : Visibility := Public_Vis;
      Is_Static   : Boolean := False;
      Is_Abstract : Boolean := False;
      Annotations : Annotation_Vectors.Vector;
   end record;

   package Member_Vectors is new Ada.Containers.Vectors
     (Positive, Member);

   --  ---------------------------------------------------------------
   --  Elements
   --  ---------------------------------------------------------------

   package Element_Index_Vectors is new Ada.Containers.Vectors
     (Positive, Element_Index);

   type Element is tagged record
      Id          : Name;
      Display     : Name;
      Kind        : Element_Kind := State;
      Annotations : Annotation_Vectors.Vector;
      Notes       : Note_Vectors.Vector;
      Members     : Member_Vectors.Vector;
      Children    : Element_Index_Vectors.Vector;
      Parent      : Element_Index := 0;
   end record;

   package Element_Vectors is new Ada.Containers.Vectors
     (Positive, Element);

   --  ---------------------------------------------------------------
   --  Relations
   --  ---------------------------------------------------------------

   type Relation_Kind is
     (Transition,
      Internal_Transition_Kind,
      Completion,
      Inheritance,
      Realization,
      Composition,
      Aggregation,
      Association,
      Dependency,
      Link);

   type Relation is tagged record
      From, To       : Element_Index := 0;
      Kind           : Relation_Kind := Transition;
      Trigger        : Name;
      Guard          : Name;
      Effect         : Name;
      Label          : Name;
      Mult_From      : Name;
      Mult_To        : Name;
      Stereotypes    : Name_Vectors.Vector;
      Notes          : Note_Vectors.Vector;
   end record;

   package Relation_Vectors is new Ada.Containers.Vectors
     (Positive, Relation);

   --  ---------------------------------------------------------------
   --  Diagram
   --  ---------------------------------------------------------------

   type Diagram is tagged record
      Id        : Name;
      Kind      : Diagram_Kind := Unknown;
      Metadata  : Metadata_Vectors.Vector;
      Elements  : Element_Vectors.Vector;
      Roots     : Element_Index_Vectors.Vector;
      Relations : Relation_Vectors.Vector;
      Notes     : Note_Vectors.Vector;
   end record;

end UML.Model;
