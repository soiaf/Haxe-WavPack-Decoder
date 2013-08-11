/*
** DecorrPass.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class DecorrPass
{
    public var term : Int;
    public var delta : Int;
    public var weight_A : Int;
    public var weight_B : Int;

    #if flash10
        public var samples_A: flash.Vector < Int >;
        public var samples_B: flash.Vector < Int >;
    #else
        public var samples_A: Array < Int >;
        public var samples_B: Array < Int >;
    #end

    public function new()
    {
        term = 0;
        delta = 0;
        weight_A = 0;
        weight_B = 0;
        #if flash10
            samples_A = new flash.Vector(Defines.MAX_TERM,true);
            samples_B = new flash.Vector(Defines.MAX_TERM,true);
        #else
            samples_A = new Array();
            samples_B = new Array();
            samples_A[Defines.MAX_TERM] = 0;	// pre-size the array (one more than needed)
            samples_B[Defines.MAX_TERM] = 0;	// pre-size the array (one more than needed)
        #end
    }
}
