/*
** WavpackContext.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class WavpackContext
{
    public var config : WavpackConfig;
    public var stream : WavpackStream;

    #if flash10  
        public var read_buffer : flash.Vector < Int >;		// stores upto FILE_BYTES_SIZE (defined in Defines.hx) bytes
    #else
        public var read_buffer : Array < Int >;				// stores upto FILE_BYTES_SIZE (defined in Defines.hx) bytes
    #end

    public var error_message : String ;
    public var error : Bool ;

    public var infile : haxe.io.Input;
    public var total_samples : Float;
    public var crc_errors : Float;
    public var first_flags : Float;
     
    public var open_flags : Int;
    public var norm_offset : Int;
    public var reduced_channels : Int;
    public var lossy_blocks : Int;
    public var status : Int;    // 0 ok, 1 error

    public function new() 
    {
        config = new WavpackConfig();
        stream = new WavpackStream();
        total_samples = 0;
        crc_errors = 0;
        first_flags = 0;
        open_flags = 0;
        norm_offset = 0;
        reduced_channels = 0;
        lossy_blocks = 0;
        status = 0;
        #if flash10
            read_buffer = new flash.Vector(Defines.FILE_BYTES_SIZE,true);
        #else
            read_buffer = new Array();
            read_buffer[Defines.FILE_BYTES_SIZE] = 0;        // presize the array, one more than required. Speed optimization.
        #end
    }
}
