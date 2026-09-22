with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package PlantUML.Classes is
   pragma Preelaborate;

   subtype Name is Unbounded_String;

   type Classifier_Kind is
     (Class, Abstract_Class, Interface_Kind, Enumeration,
      Record_Type, Annotation_Def, Stereotype_Def, Package_Kind, Object);

   type Visibility is (Public_Vis, Private_Vis, Protected_Vis, Package_Level);

   type Member_Kind is
     (Attribute, Method, Enum_Literal, Nested_Class);

   type Relation_Kind is
     (Inheritance, Realization, Composition, Aggregation,
      Association, Dependency, Link);

   type Annotation_Kind is
     (Stereotype, Note, Tag, Other);

   --  Where a note is positioned relative to its subject.
   type Note_Position is
     (Attached, Right_Of, Left_Of, Top_Of, Bottom_Of);

   type Annotation is record
      Kind     : Annotation_Kind := Other;
      Text     : Name;
      Position : Note_Position := Attached;
   end record;

   package Annotation_Vectors is
     new Ada.Containers.Vectors (Positive, Annotation);

   type Member is record
      Kind        : Member_Kind := Attribute;
      Vis         : Visibility  := Public_Vis;
      Id          : Name;
      Type_Name   : Name;
      Params      : Name;
      Is_Static   : Boolean := False;
      Is_Abstract : Boolean := False;
      Is_Class_Method : Boolean := False;
      Annotations : Annotation_Vectors.Vector;
   end record;

   package Member_Vectors is
     new Ada.Containers.Vectors (Positive, Member);

   type Class_Index is new Positive;

   package Index_Vectors is
     new Ada.Containers.Vectors (Positive, Class_Index);

   type Classifier is record
      Id          : Name;
      Display     : Name;
      Kind        : Classifier_Kind := Class;
      Parents     : Name;
      Members     : Member_Vectors.Vector;
      Annotations : Annotation_Vectors.Vector;
      Children    : Index_Vectors.Vector;
   end record;

   package Classifier_Vectors is
     new Ada.Containers.Vectors (Positive, Classifier);

   type Relation is record
      From       : Name;
      To         : Name;
      Kind       : Relation_Kind := Association;
      Mult_From  : Name;
      Mult_To    : Name;
      Label      : Name;
      Stereotype : Name;
   end record;

   package Relation_Vectors is
     new Ada.Containers.Vectors (Positive, Relation);

   type Class_Diagram is tagged record
      Diagram_Name : Name;
      Title        : Name;   --  from the "title ..." directive
      Pool         : Classifier_Vectors.Vector;
      Roots        : Index_Vectors.Vector;
      --  Diagram-level notes (floating or block form). Positional
      --  notes attached to a classifier live in Classifier.Annotations.
      Notes        : Annotation_Vectors.Vector;
      Relations    : Relation_Vectors.Vector;
   end record;

   function Parse (Source : String) return Class_Diagram;

   function Get (D : Class_Diagram; Index : Class_Index) return Classifier;

end PlantUML.Classes;