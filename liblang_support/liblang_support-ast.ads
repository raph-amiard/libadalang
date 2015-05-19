with Interfaces; use Interfaces;
with System;

with Liblang_Support.Extensions; use Liblang_Support.Extensions;
with Liblang_Support.Tokens;     use Liblang_Support.Tokens;
with Liblang_Support.Token_Data_Handler;
use Liblang_Support.Token_Data_Handler;
with Liblang_Support.Vectors;

package Liblang_Support.AST is

   type AST_Node_Type is tagged;
   type AST_Node_Access is access all AST_Node_Type;
   type AST_Node is access all AST_Node_Type'Class;

   type Extension_Type is new System.Address;
   type Extension_Access is access all Extension_Type;

   type Extension_Destructor is
     access procedure (Node      : AST_Node;
                       Extension : Extension_Type)
     with Convention => C;
   --  Type for extension destructors. The parameter are the "node" the
   --  extension was attached to and the "extension" itself.

   type Extension_Slot is record
      ID        : Extension_ID;
      Extension : Extension_Access;
      Dtor      : Extension_Destructor;
   end record;

   package Extension_Vectors is new Liblang_Support.Vectors
     (Element_Type => Extension_Slot);

   type AST_Node_Type is abstract tagged record
      Ref_Count              : Natural  := 0;
      Parent                 : AST_Node := null;

      Indent_Level           : Unsigned_16 := 0;

      Token_Data             : Token_Data_Handler_Access := null;
      Token_Start, Token_End : Natural  := 0;

      Extensions             : Extension_Vectors.Vector;
   end record;

   type Visit_Status is (Into, Over, Stop);
   type AST_Node_Kind is new Natural;

   function Kind (Node : access AST_Node_Type)
                  return AST_Node_Kind is abstract;
   function Kind_Name (Node : access AST_Node_Type) return String is abstract;
   function Image (Node : access AST_Node_Type) return String is abstract;

   function Child_Count (Node : access AST_Node_Type)
                         return Natural is abstract;
   procedure Get_Child (Node   : access AST_Node_Type;
                        Index  : Natural;
                        Exists : out Boolean;
                        Result : out AST_Node) is abstract;
   function Child (Node  : AST_Node;
                   Index : Natural) return AST_Node;

   procedure Traverse (Node : AST_Node;
                       Visit : access function (Node : AST_Node)
                                                return Visit_Status);

   procedure Compute_Indent_Level (Node : access AST_Node_Type) is abstract;

   procedure Validate (Node   : access AST_Node_Type;
                       Parent : AST_Node := null) is abstract;
   --  Perform consistency checks on Node. Check that Parent is Node's parent.

   procedure Print (Node  : access AST_Node_Type;
                    Level : Natural := 0) is abstract;

   function Sloc_Range (Node : AST_Node;
                        Snap : Boolean := False) return Source_Location_Range;
   function Lookup (Node : AST_Node;
                    Sloc : Source_Location;
                    Snap : Boolean := False) return AST_Node;
   function Compare (Node : AST_Node;
                     Sloc : Source_Location;
                     Snap : Boolean := False) return Relative_Position;

   function Lookup_Children (Node : access AST_Node_Type;
                             Sloc : Source_Location;
                             Snap : Boolean := False) return AST_Node
                                is abstract;

   procedure Lookup_Relative (Node       : AST_Node;
                              Sloc       : Source_Location;
                              Position   : out Relative_Position;
                              Node_Found : out AST_Node;
                              Snap       : Boolean := False);

   procedure Inc_Ref (Node : AST_Node);
   procedure Dec_Ref (Node : in out AST_Node);
   pragma Inline_Always (Dec_Ref);

   function Get_Extension
     (Node : AST_Node;
      ID   : Extension_ID;
      Dtor : Extension_Destructor) return Extension_Access;
   --  Get (and create if needed) the extension corresponding to ID for Node.
   --  If the extension is created, the Dtor destructor is associated to it.
   --  Note that the returned access is not guaranteed to stay valid after
   --  subsequent calls to Get_Extension.

   procedure Free (Node : access AST_Node_Type);

   function Is_Empty_List (Node : access AST_Node_Type) return Boolean is
     (False);

end Liblang_Support.AST;
