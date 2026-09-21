with Ada.Strings.Unbounded;  use Ada.Strings.Unbounded;

package body UML.Model.Queries is

   function Find_By_Id (D : UML.Model.Diagram; Name : String)
                        return UML.Model.Element_Index
   is
   begin
      for I in D.Elements.First_Index .. D.Elements.Last_Index loop
         if To_String (D.Elements (I).Id) = Name then
            return UML.Model.Element_Index (I);
         end if;
      end loop;
      return 0;
   end Find_By_Id;

   function Require_By_Id (D : UML.Model.Diagram; Name : String)
                           return UML.Model.Element_Index
   is
      Idx : constant UML.Model.Element_Index := Find_By_Id (D, Name);
   begin
      if Idx = 0 then
         raise Constraint_Error with "element not found: " & Name;
      end if;
      return Idx;
   end Require_By_Id;

   function Is_Composite (D : UML.Model.Diagram;
                          Idx : UML.Model.Element_Index) return Boolean
   is
     (D.Elements (Positive (Idx)).Kind = UML.Model.Composite_State);

   --  The parser's Region_Of scans every element's Children looking
   --  for Idx. That version is reproduced here verbatim: it does not
   --  rely on Element.Parent, which the translator does not populate.
   function Region_Of (D : UML.Model.Diagram;
                       Idx : UML.Model.Element_Index) return Natural
   is
   begin
      for I in D.Elements.First_Index .. D.Elements.Last_Index loop
         for C of D.Elements (I).Children loop
            if C = Idx then
               return I;
            end if;
         end loop;
      end loop;
      return 0;
   end Region_Of;

   function Is_History (D : UML.Model.Diagram;
                        Idx : UML.Model.Element_Index) return Boolean
   is
      K : constant UML.Model.Element_Kind :=
        D.Elements (Positive (Idx)).Kind;
   begin
      return K = UML.Model.History_Shallow
        or else K = UML.Model.History_Deep;
   end Is_History;

   function States_In (D : UML.Model.Diagram; Region : Natural)
                       return UML.Model.Element_Index_Vectors.Vector
   is
      Result : UML.Model.Element_Index_Vectors.Vector;

      procedure Consider (Idx : UML.Model.Element_Index) is
      begin
         if Idx /= 0 and then not Is_History (D, Idx) then
            Result.Append (Idx);
         end if;
      end Consider;
   begin
      if Region = 0 then
         for I of D.Roots loop
            Consider (I);
         end loop;
      else
         for C of D.Elements (Positive (Region)).Children loop
            Consider (C);
         end loop;
      end if;
      return Result;
   end States_In;

   function Composite_Children_Of
     (D : UML.Model.Diagram;
      States : UML.Model.Element_Index_Vectors.Vector)
      return UML.Model.Element_Index_Vectors.Vector
   is
      Result : UML.Model.Element_Index_Vectors.Vector;
   begin
      for S of States loop
         if Is_Composite (D, S) then
            Result.Append (S);
         end if;
      end loop;
      return Result;
   end Composite_Children_Of;

   function Transitions_In (D : UML.Model.Diagram; Region : Natural)
                            return UML.Model.Relation_Vectors.Vector
   is
      Result : UML.Model.Relation_Vectors.Vector;
   begin
      for R of D.Relations loop
         if R.Kind in UML.Model.Transition
                    | UML.Model.Internal_Transition_Kind
                    | UML.Model.Completion
         then
            declare
               From_Reg : constant Natural := Region_Of (D, R.From);
               To_Reg   : constant Natural := Region_Of (D, R.To);
               Include  : Boolean := False;
            begin
               if From_Reg = Region and then To_Reg = Region then
                  Include := True;
               elsif From_Reg = Region
                 and then Is_History (D, R.To)
                 and then Region_Of (D, R.To) = Region
               then
                  Include := True;
               end if;
               if Include then
                  Result.Append (R);
               end if;
            end;
         end if;
      end loop;
      return Result;
   end Transitions_In;

   function Parents_Of (D : UML.Model.Diagram;
                        Idx : UML.Model.Element_Index)
                        return UML.Model.Relation_Vectors.Vector
   is
      Result : UML.Model.Relation_Vectors.Vector;
   begin
      for R of D.Relations loop
         if R.To = Idx
           and then R.Kind in UML.Model.Inheritance | UML.Model.Realization
         then
            Result.Append (R);
         end if;
      end loop;
      return Result;
   end Parents_Of;

   function Associations_From (D : UML.Model.Diagram;
                               Idx : UML.Model.Element_Index)
                               return UML.Model.Relation_Vectors.Vector
   is
      Result : UML.Model.Relation_Vectors.Vector;
   begin
      for R of D.Relations loop
         if R.From = Idx
           and then R.Kind in UML.Model.Composition
                              | UML.Model.Aggregation
                              | UML.Model.Association
           and then R.To /= Idx
         then
            Result.Append (R);
         end if;
      end loop;
      return Result;
   end Associations_From;

   function Has_Parent_Method (D : UML.Model.Diagram;
                               Idx : UML.Model.Element_Index;
                               Sanitized_Method_Name : String)
                               return Boolean
   is
   begin
      for R of Parents_Of (D, Idx) loop
         for M of D.Elements (Positive (R.From)).Members loop
            if M.Kind = UML.Model.Method
              and then To_String (M.Id) = Sanitized_Method_Name
            then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Parent_Method;

end UML.Model.Queries;
