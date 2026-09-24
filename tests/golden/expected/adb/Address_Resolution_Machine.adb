---------------------------------------------------------------------
--  Address_Resolution_Machine
---------------------------------------------------------------------

package body Address_Resolution_Machine is
   use Base;

   pragma Warnings (Off);
   Table : constant array (State, Event) of State :=
     [Check_Default_Address  =>
        [Command_Sent                 => Await_Default_Response,
         Response_Detected            => Check_Default_Address,
         Relocation_Command_Sent      => Check_Default_Address,
         Winner_Data_Received         => Check_Default_Address,
         Repeat_For_Remaining_Devices => Check_Default_Address,
         Timeout_No_Devices           => Check_Default_Address,
         others                       => Check_Default_Address],
      Await_Default_Response =>
        [Command_Sent                 => Await_Default_Response,
         Response_Detected            => Relocate_Devices,
         Relocation_Command_Sent      => Await_Default_Response,
         Winner_Data_Received         => Await_Default_Response,
         Repeat_For_Remaining_Devices => Await_Default_Response,
         Timeout_No_Devices           => End_State,
         others                       => Await_Default_Response],
      Relocate_Devices       =>
        [Command_Sent                 => Relocate_Devices,
         Response_Detected            => Relocate_Devices,
         Relocation_Command_Sent      => Resolve_Collisions,
         Winner_Data_Received         => Relocate_Devices,
         Repeat_For_Remaining_Devices => Relocate_Devices,
         Timeout_No_Devices           => Relocate_Devices,
         others                       => Relocate_Devices],
      Resolve_Collisions     =>
        [Command_Sent                 => Resolve_Collisions,
         Response_Detected            => Resolve_Collisions,
         Relocation_Command_Sent      => Resolve_Collisions,
         Winner_Data_Received         => Validate_Winner,
         Repeat_For_Remaining_Devices => Resolve_Collisions,
         Timeout_No_Devices           => Resolve_Collisions,
         others                       => Resolve_Collisions],
      Validate_Winner        =>
        [Command_Sent                 => Validate_Winner,
         Response_Detected            => Validate_Winner,
         Relocation_Command_Sent      => Validate_Winner,
         Winner_Data_Received         => Validate_Winner,
         Repeat_For_Remaining_Devices => Check_Default_Address,
         Timeout_No_Devices           => Validate_Winner,
         others                       => Validate_Winner],
      Start_State            =>
        [Command_Sent                 => Start_State,
         Response_Detected            => Start_State,
         Relocation_Command_Sent      => Start_State,
         Winner_Data_Received         => Start_State,
         Repeat_For_Remaining_Devices => Start_State,
         Timeout_No_Devices           => Start_State,
         others                       => Start_State],
      End_State              =>
        [Command_Sent                 => End_State,
         Response_Detected            => End_State,
         Relocation_Command_Sent      => End_State,
         Winner_Data_Received         => End_State,
         Repeat_For_Remaining_Devices => End_State,
         Timeout_No_Devices           => End_State,
         others                       => End_State]];
   pragma Warnings (On);

   function Transition (From : State; On : Event) return State
   is (Table (From, On));

   overriding
   function Next_State (Self : Machine; On : Event) return State
   is (Table (Current_State (Self), On));

   overriding
   function Name (Self : Machine) return String is
   begin
      return "Address_Resolution_Machine";
   end Name;

   overriding
   procedure On_Enter (Self : in out Machine) is
   begin
      pragma Warnings (Off);
      case Current_State (Self) is
         --  Transmit 'Talk Register 3' to standard default address

         when Check_Default_Address  =>
            null;

         --  Wait for a response to the Talk Register 3 command

         when Await_Default_Response =>
            null;

         --  Transmit 'Listen Register 3' to default address
         --  Command all responding devices to move to a new candidate address

         when Relocate_Devices       =>
            null;

         --  Transmit 'Talk Register 3' to the new candidate address
         --  Devices reply with random IDs; collision losers revert to default

         when Resolve_Collisions     =>
            null;

         --  Receive successful payload from the single winning device

         when Validate_Winner        =>
            null;

         when Start_State            =>
            null;

         when End_State              =>
            Mark_Terminated (Self);

         when others                 =>
            null;
      end case;
   end On_Enter;

   overriding
   procedure On_Exit (Self : in out Machine) is
   begin
      pragma Warnings (Off);
      case Current_State (Self) is
         when Check_Default_Address  =>
            null;

         when Await_Default_Response =>
            null;

         when Relocate_Devices       =>
            null;

         when Resolve_Collisions     =>
            null;

         when Validate_Winner        =>
            null;

         when Start_State            =>
            null;

         when End_State              =>
            null;

         when others                 =>
            null;
      end case;
   end On_Exit;

   overriding
   procedure On_Tick (Self : in out Machine) is
   begin
      pragma Warnings (Off);
      case Current_State (Self) is
         when others =>
            null;
      end case;
   end On_Tick;

   overriding
   function On_Internal (Self : in out Machine; On : Event) return Boolean is
   begin
      pragma Warnings (Off);
      case Current_State (Self) is
         when others =>
            return False;
      end case;
   end On_Internal;

   overriding
   function Is_History_Entry
     (Self : Machine; From : State; On : Event) return Base.History_Mode
   is
      pragma Unreferenced (From, On);
   begin
      pragma Warnings (Off);
      case Current_State (Self) is
         when others =>
            return History_None;

      end case;
   end Is_History_Entry;

end Address_Resolution_Machine;
