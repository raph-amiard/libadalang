
pragma Warnings (Off, "referenced");
pragma Warnings (Off, "use clause for package");
with Libadalang.Analysis; use Libadalang.Analysis;
with Libadalang.Analysis.Properties; use Libadalang.Analysis.Properties;
pragma Warnings (On, "use clause for package");
pragma Warnings (On, "referenced");

package body Libadalang.Expr_Eval is

   ---------------
   -- Expr_Eval --
   ---------------

   function Expr_Eval (E : LAL.Expr) return Eval_Result is

      ---------------
      -- Eval_Decl --
      ---------------

      function Eval_Decl (D : LAL.Basic_Decl) return Eval_Result is
      begin
         case Kind (D) is
            when LAL.Ada_Enum_Literal_Decl =>

               --  An enum literal declaration evaluates to itself
               declare
                  Lit  : constant Enum_Literal_Decl :=
                     Enum_Literal_Decl (As_Enum_Literal_Decl (D));
                  Decl : constant Base_Type_Decl :=
                     Base_Type_Decl (As_Base_Type_Decl (P_Enum_Type (Lit)));
               begin
                  return (Enum_Lit, Decl, Lit);
               end;

            when LAL.Ada_Number_Decl =>

               --  A number declaration evaluates to the evaluation of its
               --  expression.
               return Expr_Eval (F_Expr (As_Number_Decl (D)));

            when others =>
               raise LAL.Property_Error;
         end case;
      end Eval_Decl;

   begin
      case Kind (E) is
         when LAL.Ada_Base_Id =>

            declare
               Id : constant Base_Id := Base_Id (As_Base_Id (E));
               Decl : constant Basic_Decl := Basic_Decl
                 (P_Referenced_Decl_Internal
                    (Id, Try_Immediate => True).As_Basic_Decl);
            begin
               return Eval_Decl (Decl);
            end;

         when LAL.Ada_Int_Literal =>
            return (Int,
                    Base_Type_Decl
                      (As_Base_Type_Decl (P_Universal_Int_Type (E))),
                    Long_Integer'Value
                      (LAL.Text (F_Tok (As_Int_Literal (E)))));

         when LAL.Ada_Real_Literal =>
            return (Real,
                    Base_Type_Decl
                      (As_Base_Type_Decl (P_Universal_Real_Type (E))),
                    Long_Float'Value
                      (LAL.Text (F_Tok (As_Real_Literal (E)))));

         when LAL.Ada_Bin_Op =>
            raise LAL.Property_Error;
         when LAL.Ada_Un_Op =>
            declare
               UO : LAL.Un_Op := LAL.Un_Op (As_Un_Op (E));
               Op : LAL.Op := F_Op (UO);
               Operand_Val : Eval_Result := Expr_Eval (F_Expr (UO));
            begin
               case Kind (Op) is
                  when Ada_Op_Minus =>
                     case Operand_Val.Kind is
                        when Int =>
                           return Operand_Val'Update
                             (Int_Result => -Operand_Val.Int_Result);
                        when Real =>
                           return Operand_Val'Update
                             (Real_Result => -Operand_Val.Real_Result);
                        when Enum_Lit =>
                           raise Property_Error;
                     end case;
                  when Ada_Op_Plus =>
                     return Operand_Val;
                  when others =>
                     raise Property_Error;
               end case;
            end;
         when others =>
            raise LAL.Property_Error;
      end case;
   end Expr_Eval;

   ------------
   -- As_Int --
   ------------

   function As_Int (Self : Eval_Result) return Integer is
   begin
      case Self.Kind is
         when Int => return Integer (Self.Int_Result);
         when Real => raise LAL.Property_Error;
         when Enum_Lit => return Child_Index (Self.Enum_Result) + 1;
      end case;
   end As_Int;

   -----------
   -- Image --
   -----------

   function Image (Self : Eval_Result) return String is
   begin
      return "<Eval_Result "
        & Self.Kind'Image & " "
        & (case Self.Kind is
              when Int => Self.Int_Result'Image,
              when Real => Self.Real_Result'Image,
              when Enum_Lit => Short_Image (Self.Enum_Result)) & ">";
   end Image;

end Libadalang.Expr_Eval;
