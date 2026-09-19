with Ada.Text_IO;              use Ada.Text_IO;
with HistoryTest;
with Outer_Machine;
with Middle_Machine;
with Inner_Machine;

procedure History_Test is
   use HistoryTest.Base;
   use type HistoryTest.State;
   use type Outer_Machine.State;
   use type Middle_Machine.State;
   use type Inner_Machine.State;

   M : HistoryTest.Machine;

   procedure Show (Label : String) is
      Top : constant HistoryTest.State := Current_State (M);
   begin
      Put (Label & " top=" & Top'Image);
      if Top = HistoryTest.Outer then
         declare
            O : constant Outer_Machine.State :=
              HistoryTest.Outer_State (M);
         begin
            Put (" outer=" & O'Image);
            if O = Outer_Machine.Middle then
               declare
                  Mid : constant Middle_Machine.State :=
                    HistoryTest.Outer_Middle_State (M);
               begin
                  Put (" middle=" & Mid'Image);
                  if Mid = Middle_Machine.Inner then
                     Put (" inner="
                          & HistoryTest.Outer_Middle_Inner_State
                              (M)'Image);
                  end if;
               end;
            end if;
         end;
      end if;
      New_Line;
   end Show;

begin
   Start (M);

   Step (M, HistoryTest.Enter_Fresh);
   Show ("fresh:   ");

   HistoryTest.Step_Outer_Middle_Inner (M, Inner_Machine.Advance);
   Show ("advance: ");

   Step (M, HistoryTest.Back);
   Show ("back:    ");

   Step (M, HistoryTest.Enter_Shallow);
   Show ("shallow: ");

   HistoryTest.Step_Outer_Middle_Inner (M, Inner_Machine.Advance);
   Show ("advance: ");

   Step (M, HistoryTest.Back);
   Show ("back:    ");

   Step (M, HistoryTest.Enter_Deep);
   Show ("deep:    ");
end History_Test;
