/*
** RiffChunkHeader.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class RiffChunkHeader
{
    public var ckID : Array < Int >;
    public var ckSize : Int;
    public var formType : Array < Int >;

    public function new()
    {
        ckID = new Array();
        formType = new Array();
    }
}
