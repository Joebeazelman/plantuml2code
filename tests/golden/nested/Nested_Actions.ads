--  ---------------------------------------------------------------------
--  Nested_Actions
--
--  Hand-written action bodies for Nested.
--  This file is emitted once and never overwritten. Fill in the
--  procedure bodies with your application logic.
--  ---------------------------------------------------------------------

package Nested_Actions is

   procedure Log_Idle;  --  ENTRY_ACTION: Log_Idle
   procedure Cleanup_Idle;  --  EXIT_ACTION: Cleanup_Idle
   procedure Bump;  --  INTERNAL_TRANSITION: Bump

end Nested_Actions;
