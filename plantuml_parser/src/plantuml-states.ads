with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package PlantUML.States is
   pragma Preelaborate;

   subtype Name is Unbounded_String;

   Start_Pseudostate_Name : constant String := "[*]_start";
   End_Pseudostate_Name   : constant String := "[*]_end";
   Shallow_History_Name  : constant String := "[H]";
   Deep_History_Name     : constant String := "[H*]";

   type State_Kind is
     (Simple,
      Composite,
      Submachine_Reference,
      Start_Pseudostate,
      End_Pseudostate,
      Choice_Pseudostate,
      Fork_Pseudostate,
      Join_Pseudostate,
      History_Shallow,
      History_Deep,
      Entry_Point,
      Exit_Point);

   type Annotation_Kind is
     (Entry_Action,
      Exit_Action,
      Do_Activity,
      Internal_Transition,
      Note,
      Stereotype,
      Unknown);

   type Transition_Kind is
     (External,
      Internal,
      Local,
      Completion);

   type Annotation is record
      Kind    : Annotation_Kind := Unknown;
      Action  : Name;
      Trigger : Name;
      Guard   : Name;
   end record;

   package Annotation_Vectors is
     new Ada.Containers.Vectors (Positive, Annotation);

   type State_Index is new Positive;

   package Index_Vectors is
     new Ada.Containers.Vectors (Positive, State_Index);

   type State is record
      Id          : Name;
      Display     : Name;
      Kind        : State_Kind := Simple;
      Annotations : Annotation_Vectors.Vector;
      Children    : Index_Vectors.Vector;
   end record;

   package State_Vectors is
     new Ada.Containers.Vectors (Positive, State);

   type Transition is record
      From    : Name;
      To      : Name;
      Trigger : Name;
      Guard   : Name;
      Effect  : Name;
      Label   : Name;
      Kind    : Transition_Kind := External;
   end record;

   package Transition_Vectors is
     new Ada.Containers.Vectors (Positive, Transition);

   type State_Diagram is tagged record
      Diagram_Name : Name;
      Title        : Name;   --  from the "title ..." directive
      Pool         : State_Vectors.Vector;
      Roots        : Index_Vectors.Vector;
      Transitions  : Transition_Vectors.Vector;
   end record;

   function Parse (Source : String) return State_Diagram;

   function Get (D : State_Diagram; Index : State_Index) return State;

end PlantUML.States;
