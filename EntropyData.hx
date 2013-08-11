/*
** EntropyData.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class EntropyData
{
    public var slow_level : Int;
    public var median : Array < Int >;
    public var error_limit : Int;

    public function new()
    {
        slow_level = 0;
        median = [0,0,0];
        error_limit = 0;
    }
}
