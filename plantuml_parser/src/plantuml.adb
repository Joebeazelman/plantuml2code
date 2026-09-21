with Ada.Characters.Handling;  use Ada.Characters.Handling;
with Ada.Strings.Fixed;        use Ada.Strings.Fixed;

with PlantUML.States;
with PlantUML.Classes;
with PlantUML.To_Model;

package body PlantUML is
   function Detect_Kind (Source : String) return Diagram_Kind is
      L : constant String := To_Lower (Source);
   begin
      --  Class-diagram triggers mirror the keywords the class parser
      --  recognises (see PlantUML.Classes). Any of these appearing
      --  inside @startuml/@enduml means we route to the class parser.
      return (if Index (L, "@startstate") > 0
                 or else (Index (L, "@startuml") > 0
                          and then Index (L, "state ") > 0)
              then State_Diagram
              elsif Index (L, "@startclass") > 0
                 or else (Index (L, "@startuml") > 0
                          and then (Index (L, "class ") > 0
                                    or else Index (L, "abstract ") > 0
                                    or else Index (L, "interface ") > 0
                                    or else Index (L, "enum ") > 0
                                    or else Index (L, "record ") > 0
                                    or else Index (L, "annotation ") > 0
                                    or else Index (L, "package ") > 0
                                    or else Index (L, "object ") > 0))
              then Class_Diagram
              else Unknown);
   end Detect_Kind;

   function Parse (Source : String) return UML.Model.Diagram is
   begin
      case Detect_Kind (Source) is
         when State_Diagram =>
            return PlantUML.To_Model.From_State
                     (PlantUML.States.Parse (Source));
         when Class_Diagram =>
            return PlantUML.To_Model.From_Classes
                     (PlantUML.Classes.Parse (Source));
         when Unknown =>
            declare
               R : UML.Model.Diagram;
            begin
               R.Kind := UML.Model.Unknown;
               return R;
            end;
      end case;
   end Parse;
end PlantUML;
