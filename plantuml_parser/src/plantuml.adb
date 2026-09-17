with Ada.Characters.Handling;  use Ada.Characters.Handling;
with Ada.Strings.Fixed;        use Ada.Strings.Fixed;

package body PlantUML is
   function Detect_Kind (Source : String) return Diagram_Kind is
      L : constant String := To_Lower (Source);
   begin
      return (if Index (L, "@startstate") > 0
                 or else (Index (L, "@startuml") > 0
                          and then Index (L, "state ") > 0)
              then State_Diagram
              elsif Index (L, "@startclass") > 0
                 or else (Index (L, "@startuml") > 0
                          and then (Index (L, "class ") > 0
                                    or else Index (L, "interface ") > 0))
              then Class_Diagram
              else Unknown);
   end Detect_Kind;
end PlantUML;
