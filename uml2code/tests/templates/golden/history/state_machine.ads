--  state_machine.ads -- root of the state-machine hierarchy.
--  Emitted once. Edit freely.

package State_Machine is
   pragma Pure;

   type Root is abstract tagged limited null record;

   function Name (Self : Root) return String is abstract;

end State_Machine;
