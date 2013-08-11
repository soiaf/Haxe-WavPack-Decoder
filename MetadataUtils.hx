/*
** MetadataUtils.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class MetadataUtils
{
    public static function read_metadata_buff(wpc : WavpackContext, wpmd : WavpackMetadata) : Int
    {
        var bytes_to_read : Float;
        var tchar : Int;

	  if (wpmd.bytecount >= wpc.stream.wphdr.ckSize)
        {
            // we have read all the data in this block
            return Defines.FALSE;
        }

        try
        {
            wpmd.id = wpc.infile.readByte();
            tchar =  wpc.infile.readByte();
        }
        catch (err: Dynamic)
        {
            wpmd.status = 1;
            return Defines.FALSE;
        }

        wpmd.bytecount += 2;

        wpmd.byte_length = tchar << 1;

        if ((wpmd.id & Defines.ID_LARGE) != 0)
        {
			wpmd.id &= ~Defines.ID_LARGE;
            
            try
            {
                tchar = wpc.infile.readByte();
            }
            catch (err: Dynamic)
            {
                wpmd.status = 1;
                return Defines.FALSE;
            }

            wpmd.byte_length +=  tchar << 9;

            try
            {
                tchar = wpc.infile.readByte();
            }
            catch (err: Dynamic)
            {
                wpmd.status = 1;
                return Defines.FALSE;
            }

            wpmd.byte_length += tchar << 17;
            wpmd.bytecount += 2;
        }

        if ((wpmd.id & Defines.ID_ODD_SIZE) != 0)
        {
			wpmd.id &= ~Defines.ID_ODD_SIZE;          
            wpmd.byte_length--;
        }

        if (wpmd.byte_length == 0 || wpmd.id == Defines.ID_WV_BITSTREAM)
        {
            wpmd.hasdata = Defines.FALSE;
            return Defines.TRUE;
        }

        bytes_to_read = wpmd.byte_length + (wpmd.byte_length & 1);

        wpmd.bytecount += bytes_to_read;

        if (bytes_to_read > Defines.WPC_READ_BUFFER_LENGTH)
        {
	      var bytes_read : Int;
            wpmd.hasdata = Defines.FALSE;
            var temp_buffer = haxe.io.Bytes.alloc(Defines.WPC_READ_BUFFER_LENGTH);

            while (bytes_to_read > Defines.WPC_READ_BUFFER_LENGTH)
            {
                try
                {
                    bytes_read = wpc.infile.readBytes(temp_buffer, 0, Defines.WPC_READ_BUFFER_LENGTH);
                    for (i in 0 ... bytes_read)
                    {
                        wpc.read_buffer[i] = temp_buffer.get(i);
                    }
                    if(bytes_read != Defines.WPC_READ_BUFFER_LENGTH)
                    {
                        return Defines.FALSE;
                    }
                }
                catch (err: Dynamic)
                {
                    return Defines.FALSE;
                }
                bytes_to_read -= Defines.WPC_READ_BUFFER_LENGTH;
            }
        }
        else
        {
            wpmd.hasdata = Defines.TRUE;
            wpmd.data = wpc.read_buffer;
        }

        if (bytes_to_read != 0)
        {
            var bytes_read : Int;
            var temp_buffer = haxe.io.Bytes.alloc(Defines.WPC_READ_BUFFER_LENGTH);

            try
            {
                bytes_read = wpc.infile.readBytes(temp_buffer, 0,  Math.floor(bytes_to_read));
                for (i in 0 ... bytes_read)
                {
                    wpc.read_buffer[i] = temp_buffer.get(i);
                }
                if(bytes_read != bytes_to_read)
                {
                    wpmd.hasdata = Defines.FALSE;
                    return Defines.FALSE;
                }
            }
            catch (err: Dynamic)
            {
                wpmd.hasdata = Defines.FALSE;
                return Defines.FALSE;
            }
        }

        return Defines.TRUE;
    }

    public static function process_metadata(wpc : WavpackContext, wpmd : WavpackMetadata) : Int
    {
        var wps : WavpackStream = wpc.stream;

        switch (wpmd.id)
        {
            case Defines.ID_DUMMY:
            {
                return Defines.TRUE;
            }            

            case Defines.ID_DECORR_TERMS:
            {
                return UnpackUtils.read_decorr_terms(wps, wpmd);
            }

            case Defines.ID_DECORR_WEIGHTS:
            {
                return UnpackUtils.read_decorr_weights(wps, wpmd);
            }

            case Defines.ID_DECORR_SAMPLES:
            {
                return UnpackUtils.read_decorr_samples(wps, wpmd);
            }

            case Defines.ID_ENTROPY_VARS:
            {
                return WordsUtils.read_entropy_vars(wps, wpmd);
            }

            case Defines.ID_HYBRID_PROFILE:
            {
                return WordsUtils.read_hybrid_profile(wps, wpmd);
            }

            case Defines.ID_FLOAT_INFO:
            {
                return FloatUtils.read_float_info(wps, wpmd);
            }
            
            case Defines.ID_INT32_INFO:
            {
                return UnpackUtils.read_int32_info(wps, wpmd);
            }

            case Defines.ID_CHANNEL_INFO:
            {
                return UnpackUtils.read_channel_info(wpc, wpmd);
            }

            case Defines.ID_SAMPLE_RATE:
            {
                return UnpackUtils.read_sample_rate(wpc, wpmd);
            }

            case Defines.ID_CONFIG_BLOCK:
            {
                return UnpackUtils.read_config_info(wpc, wpmd);
            }

            case Defines.ID_WV_BITSTREAM:
            {
                return UnpackUtils.init_wv_bitstream(wpc, wpmd);
            }

            case Defines.ID_SHAPING_WEIGHTS:
            {
                return Defines.TRUE;
            }
            case Defines.ID_WVC_BITSTREAM:
            {
                return Defines.TRUE;
            }
            case Defines.ID_WVX_BITSTREAM:
            {
                return Defines.TRUE;
            }
            
            default:
            {           
                if ((wpmd.id & Defines.ID_OPTIONAL_DATA) != 0)
                {
                    return Defines.TRUE;
                }
                else
                {
                    return Defines.FALSE;
                }
            }
        }       
    }
}
