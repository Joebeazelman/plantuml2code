--  ---------------------------------------------------------------------
--  Nested_Actions (body)
--
--  Hand-written action bodies. Emitted once and never overwritten.
--  ---------------------------------------------------------------------

package body Nested_Actions is

   procedure Log_Idle is
   begin
      null;  --  TODO: ENTRY_ACTION: Log_Idle
   end Log_Idle;

   procedure Cleanup_Idle is
   begin
      null;  --  TODO: EXIT_ACTION: Cleanup_Idle
   end Cleanup_Idle;

   procedure Bump is
   begin
      null;  --  TODO: INTERNAL_TRANSITION: Bump
   end Bump;


end Nested_Actions;
