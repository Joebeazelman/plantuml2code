with Ada.Text_IO;              use Ada.Text_IO;
with Ada.Strings.Unbounded;    use Ada.Strings.Unbounded;

with UML.Model;                use UML.Model;

package body Uml2Code_Model_Dump is

   procedure Dump (D : UML.Model.Diagram) is
   begin
      Put_Line ("Diagram: "
                & (if Length (D.Id) > 0
                   then To_String (D.Id) else "<unnamed>"));
      Put_Line ("  Kind: " & D.Kind'Image);

      if not D.Metadata.Is_Empty then
         Put_Line ("  Metadata:");
         for M of D.Metadata loop
            Put_Line ("    [" & M.Kind'Image & "] "
                      & To_String (M.Text));
         end loop;
      end if;

      Put_Line ("  Elements (" & D.Elements.Length'Image & "):");
      for I in D.Elements.First_Index .. D.Elements.Last_Index loop
         declare
            E : constant UML.Model.Element := D.Elements (I);
         begin
            Put_Line ("    " & I'Image & ": "
                      & To_String (E.Id)
                      & "  kind=" & E.Kind'Image
                      & (if Length (E.Display) > 0
                         then "  as=" & To_String (E.Display) else "")
                      & (if E.Parent /= 0
                         then "  parent=" & E.Parent'Image else ""));
            for A of E.Annotations loop
               Put_Line ("       ann " & A.Kind'Image
                         & (if Length (A.Trigger) > 0
                            then "  trigger=" & To_String (A.Trigger) else "")
                         & (if Length (A.Guard) > 0
                            then "  guard=[" & To_String (A.Guard) & "]"
                            else "")
                         & (if Length (A.Text) > 0
                            then "  text=" & To_String (A.Text) else ""));
            end loop;
            for N of E.Notes loop
               Put_Line ("       note (" & N.Position'Image & ") "
                         & To_String (N.Text));
            end loop;
            if not E.Children.Is_Empty then
               declare
                  S : Unbounded_String := To_Unbounded_String ("[");
                  First : Boolean := True;
               begin
                  for C of E.Children loop
                     if not First then
                        Append (S, ", ");
                     end if;
                     Append (S, C'Image);
                     First := False;
                  end loop;
                  Append (S, "]");
                  Put_Line ("       children=" & To_String (S));
               end;
            end if;
            for M of E.Members loop
               Put_Line ("       member " & M.Kind'Image
                         & " " & M.Vis'Image
                         & (if M.Is_Abstract then " (abstract)" else "")
                         & " " & To_String (M.Id)
                         & (if Length (M.Type_Name) > 0
                            then " : " & To_String (M.Type_Name) else ""));
            end loop;
         end;
      end loop;

      Put_Line ("  Relations (" & D.Relations.Length'Image & "):");
      for R of D.Relations loop
         Put_Line ("    " & R.From'Image
                   & " -> " & R.To'Image
                   & "  kind=" & R.Kind'Image
                   & (if Length (R.Trigger) > 0
                      then "  trigger=" & To_String (R.Trigger) else "")
                   & (if Length (R.Guard) > 0
                      then "  guard=[" & To_String (R.Guard) & "]" else "")
                   & (if Length (R.Effect) > 0
                      then "  effect=" & To_String (R.Effect) else "")
                   & (if Length (R.Label) > 0
                      then "  label=" & To_String (R.Label) else ""));
      end loop;

      if not D.Notes.Is_Empty then
         Put_Line ("  Standalone notes:");
         for N of D.Notes loop
            Put_Line ("    " & To_String (N.Text));
         end loop;
      end if;
   end Dump;

end Uml2Code_Model_Dump;
