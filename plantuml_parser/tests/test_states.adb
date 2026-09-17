with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with PlantUML.States;          use PlantUML.States;

procedure Test_States is

   Src : constant String :=
     "@startuml Nested"                             & ASCII.LF &
     "[*] --> Idle"                                 & ASCII.LF &
     "state Idle"                                   & ASCII.LF &
     "Idle : entry / Log_Idle"                      & ASCII.LF &
     "Idle : exit / Cleanup_Idle"                   & ASCII.LF &
     "Idle : Tick [Count < 10] / Bump"              & ASCII.LF &
     "Idle --> Running : Start"                     & ASCII.LF &
     "state Running {"                              & ASCII.LF &
     "  [*] --> Spinning"                           & ASCII.LF &
     "  state Spinning"                             & ASCII.LF &
     "  Spinning : do / Poll"                       & ASCII.LF &
     "  Spinning : Pause / Halt"                    & ASCII.LF &
     "  Spinning --> Waiting : Yield"               & ASCII.LF &
     "  state Waiting"                              & ASCII.LF &
     "  Waiting --> Spinning : Resume"              & ASCII.LF &
     "  Waiting --> [H] : Suspend"                  & ASCII.LF &
     "}"                                            & ASCII.LF &
     "Running --> Idle : Stop"                      & ASCII.LF &
     "Running --> [*] : Finish"                     & ASCII.LF &
     "@enduml";

   D : constant State_Diagram := Parse (Src);

   procedure Dump_State (D : State_Diagram;
                         Idx : State_Index;
                         Depth : Natural) is
      Pad : constant String (1 .. Depth * 2) := [others => ' '];
      S   : constant State := Get (D, Idx);
   begin
      Put_Line (Pad & "- " & To_String (S.Id)
                & "  kind=" & S.Kind'Image
                & (if Length (S.Display) > 0
                   then "  as=" & To_String (S.Display) else ""));
      for A of S.Annotations loop
         Put_Line (Pad & "    * ann=" & A.Kind'Image
                   & (if Length (A.Trigger) > 0
                      then "  trigger=" & To_String (A.Trigger) else "")
                   & (if Length (A.Guard) > 0
                      then "  guard=[" & To_String (A.Guard) & "]" else "")
                   & (if Length (A.Action) > 0
                      then "  body=" & To_String (A.Action) else ""));
      end loop;
      for I in S.Children.First_Index .. S.Children.Last_Index loop
         Dump_State (D, S.Children (I), Depth + 1);
      end loop;
   end Dump_State;

begin
   Put_Line ("Diagram: " & To_String (D.Diagram_Name));
   Put_Line ("Pool:" & D.Pool.Length'Image);
   Put_Line ("Roots:" & D.Roots.Length'Image);
   for I in D.Roots.First_Index .. D.Roots.Last_Index loop
      Dump_State (D, D.Roots (I), 1);
   end loop;

   Put_Line ("Transitions:" & D.Transitions.Length'Image);
   for T of D.Transitions loop
      Put_Line ("  " & To_String (T.From)
                & " -> " & To_String (T.To)
                & "  kind=" & T.Kind'Image
                & (if Length (T.Trigger) > 0
                   then "  trigger=" & To_String (T.Trigger) else "")
                & (if Length (T.Guard) > 0
                   then "  guard=[" & To_String (T.Guard) & "]" else "")
                & (if Length (T.Effect) > 0
                   then "  effect=" & To_String (T.Effect) else ""));
   end loop;
end Test_States;
