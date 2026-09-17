with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;
with PlantUML.Classes;         use PlantUML.Classes;

procedure Test_Classes is

   Src : constant String :=
     "@startuml Zoo"                                     & ASCII.LF &
     "package Animals {"                                 & ASCII.LF &
     "  abstract class Animal {"                         & ASCII.LF &
     "    #name : String"                                & ASCII.LF &
     "    +Speak() : void"                               & ASCII.LF &
     "    +{abstract} Move()"                            & ASCII.LF &
     "  }"                                               & ASCII.LF &
     "  class Dog {"                                     & ASCII.LF &
     "    +Fetch()"                                      & ASCII.LF &
     "  }"                                               & ASCII.LF &
     "  interface Pet {"                                 & ASCII.LF &
     "    +Name() : String"                              & ASCII.LF &
     "  }"                                               & ASCII.LF &
     "}"                                                 & ASCII.LF &
     "enum Color {"                                      & ASCII.LF &
     "  Red"                                             & ASCII.LF &
     "  Green"                                           & ASCII.LF &
     "  Blue"                                            & ASCII.LF &
     "}"                                                 & ASCII.LF &
     "Animal <|-- Dog"                                   & ASCII.LF &
     "Pet <|.. Dog"                                      & ASCII.LF &
     "Dog ""1"" *-- ""many"" Toy : owns"                 & ASCII.LF &
     "class Toy"                                         & ASCII.LF &
     "Dog --> Color : has"                               & ASCII.LF &
     "@enduml";

   D : constant Class_Diagram := Parse (Src);

   procedure Dump_Class (D : Class_Diagram;
                         Idx : Class_Index;
                         Depth : Natural) is
      Pad : constant String (1 .. Depth * 2) := [others => ' '];
      K   : constant Classifier := Get (D, Idx);
   begin
      Put_Line (Pad & "- " & To_String (K.Id)
                & "  kind=" & K.Kind'Image
                & (if Length (K.Display) > 0
                   then "  as=" & To_String (K.Display) else ""));
      for M of K.Members loop
         Put_Line (Pad & "    * " & M.Kind'Image
                   & " vis=" & M.Vis'Image
                   & (if M.Is_Static   then " static"   else "")
                   & (if M.Is_Abstract then " abstract" else "")
                   & "  " & To_String (M.Id)
                   & (if Length (M.Params) > 0
                      then "(" & To_String (M.Params) & ")" else "")
                   & (if Length (M.Type_Name) > 0
                      then " : " & To_String (M.Type_Name) else ""));
      end loop;
      for C of K.Children loop
         Dump_Class (D, C, Depth + 1);
      end loop;
   end Dump_Class;

begin
   Put_Line ("Diagram: " & To_String (D.Diagram_Name));
   Put_Line ("Pool:" & D.Pool.Length'Image);
   Put_Line ("Roots:" & D.Roots.Length'Image);
   for I in D.Roots.First_Index .. D.Roots.Last_Index loop
      Dump_Class (D, D.Roots (I), 1);
   end loop;

   Put_Line ("Relations:" & D.Relations.Length'Image);
   for R of D.Relations loop
      Put_Line ("  " & To_String (R.From)
                & " " & R.Kind'Image
                & " " & To_String (R.To)
                & (if Length (R.Mult_To) > 0
                   then "  [" & To_String (R.Mult_To) & "]" else "")
                & (if Length (R.Label) > 0
                   then "  : " & To_String (R.Label) else ""));
   end loop;
end Test_Classes;