/*
** WavpackMetadata.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class WavpackMetadata
{
    public var byte_length : Int;
    
    #if flash10
        public var data : flash.Vector < Int >;
    #else
        public var data : Array < Int >;
    #end

    public var id : Int;
    public var hasdata : Int;	// 0 does not have data, 1 has data
    public var status : Int;	// 0 ok, 1 error
    public var bytecount : Float;// we use this to determine if we have read all the metadata 
                      	// in a block by checking bytecount again the block length
                   	// ckSize is block size minus 8. WavPack header is 32 bytes long so we start at 24

    public function new()
    {
        hasdata = 0;
        status = 0;
        bytecount = 24;
 
        #if flash10
            data = new flash.Vector(Defines.FILE_BYTES_SIZE,true);
        #else
            data = new Array();
            data[Defines.FILE_BYTES_SIZE] = 0;     // presize the array, slightly larger than needed. 
        #end
    }
}
