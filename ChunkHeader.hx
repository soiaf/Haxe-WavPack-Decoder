/*
** ChunkHeader.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
*/

class ChunkHeader
{
    public var ckID : Array < Int >;
    public var ckSize : Int;

    public function new()
    {
        ckID = new Array();
    }
}
