/*
** Bitstream.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)
**
*/

class Bitstream
{
    public var end : Int;
    public var ptr : Int;
    public var file_bytes : Int;
    public var sr : Int;
    public var error : Int;
    public var bc : Int;
    public var file : haxe.io.Input;
    public var bitval : Int;

    #if flash10
        public var buf : flash.Vector < Int >;
    #else
        public var buf : Array <Int >;
    #end    

    public var buf_index : Int;

    public function new()
    {
        bitval = 0;
        buf_index = 0;

        #if flash10
            buf = new flash.Vector(Defines.FILE_BYTES_SIZE,true);
        #else
            buf = new Array();
            buf[Defines.FILE_BYTES_SIZE] = 0;	// pre-size the array (one more than we need)
        #end
    }
}
