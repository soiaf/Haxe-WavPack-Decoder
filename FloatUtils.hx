/*
** FloatUtils.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class FloatUtils
{

    public static function read_float_info (wps : WavpackStream, wpmd : WavpackMetadata) : Int
    {
        var bytecnt : Int = wpmd.byte_length;
        #if flash10
            var byteptr : flash.Vector < Int > = wpmd.data;
        #else
            var byteptr : Array < Int > = wpmd.data;
        #end

        var counter : Int = 0;

        if (bytecnt != 4)
            return Defines.FALSE;

        wps.float_flags = byteptr[counter];
        counter++;
        wps.float_shift = byteptr[counter];
        counter++;
        wps.float_max_exp = byteptr[counter];
        counter++;
        wps.float_norm_exp = byteptr[counter];
  
        return Defines.TRUE;
    }
	 
#if flash10
	public static function float_values (wps : WavpackStream, values : flash.Vector < Int >, num_values : Float, bufferStartPos : Int) : flash.Vector < Int >
#else	
	public static function float_values (wps : WavpackStream,  values : Array < Int >, num_values : Float, bufferStartPos : Int) : Array < Int >
#end	
    {
        var shift : Int = wps.float_max_exp - wps.float_norm_exp + wps.float_shift;
        var value_counter : Int = bufferStartPos;

        if (shift > 32)
            shift = 32;
        else if (shift < -32)
            shift = -32;

        while (num_values>0) 
        {
            if (shift > 0)
                values[value_counter] <<= shift;
            else if (shift < 0)
                values[value_counter] >>= -shift;

            if (values[value_counter] > 8388607)
                values[value_counter] = 8388607;
            else if (values[value_counter] < -8388608)
                values[value_counter] = -8388608;

            value_counter++;
			num_values--;
        }

        return values;
    }
}
