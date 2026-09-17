--  Abstract root of the state-machine hierarchy.

package HSM is
   pragma Preelaborate;

   type Root is abstract tagged limited null record;

   function Name (Self : Root) return String is abstract;

end HSM;
