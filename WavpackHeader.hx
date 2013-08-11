/*
** WavpackHeader.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class WavpackHeader
{
    public var ckID : Array < Int >;
    public var ckSize : Float;
    public var version : Int;
    public var track_no : Int;
    public var index_no : Int;
    public var total_samples : Float;
    public var block_index : Float;
    public var block_samples : Float;
    public var flags : Int;
    public var crc : Int;
    public var status : Int;	// 1 means error

    public function new()
    {
        ckID = new Array();
        block_samples = 0;
    }
}
