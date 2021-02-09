procedure TestIfc is
   package Pkg is
      type Root_Interface is interface;
      procedure Foo (Self : Root_Interface; Nat : Natural) is null;

      type Derived is interface and Root_Interface;
      procedure Bar (Self : Derived) is null;
   end Pkg;

   use Pkg;

   Inst : Derived'Class;
begin
   Foo (Inst, 12);
   pragma Test_Statement;
end Testifc;
