/*
** WaveHeader.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)
**
*/

class WaveHeader
{
    public var FormatTag : Int;
    public var NumChannels : Int;
    public var SampleRate : Float;
    public var BytesPerSecond : Float;
    public var BlockAlign : Int;
    public var BitsPerSample : Int;

    public function new()
    {
        FormatTag = 0;
        NumChannels = 0;
        BlockAlign = 0;
        BitsPerSample = 0;
    }
}
