/*
** WordsData.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class WordsData
{
    #if flash10
        public var bitrate_delta : flash.Vector < Int >;
        public var bitrate_acc : flash.Vector < Int >;
    #else
        public var bitrate_delta : Array < Int >;
        public var bitrate_acc : Array < Int >;
    #end
    public var pend_data : Int;
    public var holding_one : Int;
    public var zeros_acc : Int;  
    public var holding_zero : Int;
    public var pend_count : Int;

    public var temp_ed1 : EntropyData;
    public var temp_ed2 : EntropyData;
    public var c : Array < EntropyData >;

    public function new()
    {
        #if flash10
            bitrate_delta = new flash.Vector(2,true);
            bitrate_delta[0] = 0;
            bitrate_delta[1] = 0;
            bitrate_acc = new flash.Vector(2,true);
            bitrate_acc[0] = 0;
            bitrate_acc[1] = 0;
        #else
            bitrate_delta = new Array();
            bitrate_delta = [0,0];
            bitrate_acc = new Array();
            bitrate_acc = [0,0];
        #end

        pend_data = 0;
        holding_one = 0;
        zeros_acc = 0;
        holding_zero = 0;
        pend_count = 0;
        temp_ed1 = new EntropyData();
        temp_ed2 = new EntropyData();
        c = [temp_ed1 , temp_ed2 ];
    }

}
