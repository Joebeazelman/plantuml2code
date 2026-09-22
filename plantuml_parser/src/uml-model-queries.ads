--  Structural queries over UML.Model.Diagram.
--
--  The model itself is flat: Elements carry an optional Parent, and
--  Relations carry From/To indices. The generators, however, think in
--  terms of regions (a composite and its children), parent chains, and
--  transitions scoped to a region. This package reconstructs those
--  views without adding fields to the model.
--
--  Types only in UML.Model; queries here. Generators use both.

package UML.Model.Queries is
   pragma Preelaborate;

   --  ---------------------------------------------------------------
   --  Lookup
   --  ---------------------------------------------------------------

   --  Index of the element whose Id equals Name, or 0 if absent.
   function Find_By_Id (D : UML.Model.Diagram; Name : String)
                        return UML.Model.Element_Index;

   --  Index of the element whose Id equals Name; raises if absent.
   function Require_By_Id (D : UML.Model.Diagram; Name : String)
                           return UML.Model.Element_Index;

   --  ---------------------------------------------------------------
   --  Regions
   --  ---------------------------------------------------------------
   --
   --  A "region" is either the diagram's top level (index 0) or a
   --  composite element. A state belongs to the region of its nearest
   --  composite ancestor, or to the top level if it has none.

   --  Region index of an element: 0 for top level, else the nearest
   --  composite ancestor. Pseudostates inherit their parent's region.
   function Region_Of (D : UML.Model.Diagram;
                       Idx : UML.Model.Element_Index) return Natural;

   --  Elements belonging to the given region, in diagram order.
   --  Region = 0 selects roots; otherwise the region element's
   --  Children. History pseudostates are excluded: they are targets,
   --  never states.
   function States_In (D : UML.Model.Diagram; Region : Natural)
                       return UML.Model.Element_Index_Vectors.Vector;

   --  True if the element is a composite (has children or is declared
   --  Composite_State).
   function Is_Composite (D : UML.Model.Diagram;
                          Idx : UML.Model.Element_Index) return Boolean;

   --  Composite children of the given state list, in order. Convenience
   --  for the state generator, which recurses into each.
   function Composite_Children_Of
     (D : UML.Model.Diagram;
      States : UML.Model.Element_Index_Vectors.Vector)
      return UML.Model.Element_Index_Vectors.Vector;

   --  ---------------------------------------------------------------
   --  Transitions
   --  ---------------------------------------------------------------

   --  Transitions whose From and To both resolve to Region, plus
   --  transitions into a history pseudostate that is itself a direct
   --  child of Region (history entries restart a region).
   function Transitions_In (D : UML.Model.Diagram; Region : Natural)
                            return UML.Model.Relation_Vectors.Vector;

   --  True if the element is a shallow or deep history pseudostate.
   function Is_History (D : UML.Model.Diagram;
                        Idx : UML.Model.Element_Index) return Boolean;

   --  ---------------------------------------------------------------
   --  Class-diagram helpers
   --  ---------------------------------------------------------------

   --  Relations whose To (for inheritance/realization) is Idx.
   function Parents_Of (D : UML.Model.Diagram;
                        Idx : UML.Model.Element_Index)
                        return UML.Model.Relation_Vectors.Vector;

   --  Relations whose From is Idx and whose Kind is one of the
   --  composition/aggregation/association set.
   function Associations_From (D : UML.Model.Diagram;
                               Idx : UML.Model.Element_Index)
                               return UML.Model.Relation_Vectors.Vector;

   --  True if any relation targeting Idx is a method with the given
   --  sanitized name, directly on the parent. Used to decide
   --  "overriding".
   function Has_Parent_Method (D : UML.Model.Diagram;
                               Idx : UML.Model.Element_Index;
                               Sanitized_Method_Name : String)
                               return Boolean;

end UML.Model.Queries;
