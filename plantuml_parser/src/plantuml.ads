with UML.Model;

package PlantUML is
   pragma Preelaborate;

   Parse_Error : exception;

   type Diagram_Kind is (Unknown, State_Diagram, Class_Diagram);

   function Detect_Kind (Source : String) return Diagram_Kind;

   function Parse (Source : String) return UML.Model.Diagram;

end PlantUML;
