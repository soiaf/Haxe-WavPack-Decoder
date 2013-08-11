/*
** WavpackConfig.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class WavpackConfig
{
    public var bits_per_sample : Int;
    public var bytes_per_sample : Int;
    public var num_channels : Int;
    public var float_norm_exp : Int;
    public var flags : Int;
    public var sample_rate : Float;
    public var channel_mask : Float;

    public function new()
    {
        bits_per_sample = 0;
        bytes_per_sample = 0;
        num_channels = 0;
        float_norm_exp  = 0;
        flags = 0;
        sample_rate = 0; 
        channel_mask = 0;
    }
}
