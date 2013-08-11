/*
** BitsUtils.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class BitsUtils
{

    public static function getbit(bs : Bitstream) : Bitstream
    {   
        if (bs.bc > 0)
        {
            bs.bc--;
        }
        else
        {
            bs.ptr++;
            bs.buf_index++;
            bs.bc = 7;

            if (bs.ptr == bs.end)
            {
                // wrap call here
                bs = bs_read(bs);
            }
            bs.sr = (bs.buf[bs.buf_index] & 0xff);
        }

        bs.bitval = (bs.sr & 1);
        
        bs.sr = bs.sr >> 1;    
        
        return bs;
    }

    public static function getbits(nbits : Int, bs : Bitstream) : Int
    {
        var uns_buf : Int  = 0;
        var value : Int = 0;

        while ((nbits) > bs.bc)
        {
            bs.ptr++;
            bs.buf_index++;

            if (bs.ptr == bs.end)
            {
                bs = bs_read(bs);
            }
           
            uns_buf = (bs.buf[bs.buf_index] & 0xff);
            bs.sr = bs.sr | (uns_buf << bs.bc); // values in buffer must be unsigned
            
            bs.sr = bs.sr & 0xFFFFFFFF;        // sr is an unsigned 32 bit variable
            bs.bc += 8;         
        }

        value = bs.sr;

        if (bs.bc > 32)
        {
            bs.bc -= (nbits);
            bs.sr = (bs.buf[bs.buf_index] & 0xff) >> (8 - bs.bc);            
        }
        else
        {    
            bs.bc -= (nbits);
            
            if(bs.sr < 0) 
            {
				// bs.sr should be a 32 bit unsigned value, this is not something that currently exists in Haxe.
				// To replicate the necessary functionality, when we are right shifting, I shift once, then
				// remove the sign bit (by and-ing with 0x7fffffff) and then doing the remainding right shift.
				
                if(nbits>0)
                {
                    bs.sr = bs.sr >> 1;
                    bs.sr = (bs.sr & 0x7fffffff) >> (nbits-1);
                }
            }
            else
            {
                bs.sr >>= (nbits);
            }            
        }

        return (value);
    }

    #if flash10
    public static function bs_open_read(stream : flash.Vector < Int >, buffer_start : Int, buffer_end : Int, file : haxe.io.Input,
        file_bytes : Int, passed : Int) : Bitstream
    #else
    public static function bs_open_read(stream : Array < Int >, buffer_start : Int, buffer_end : Int, file : haxe.io.Input,
        file_bytes : Int, passed : Int) : Bitstream
    #end 
    {
        var bs : Bitstream = new Bitstream();

        bs.buf = stream;
        bs.buf_index = buffer_start;
        bs.end = buffer_end;
        bs.sr = 0;
        bs.bc = 0;

        if (passed != 0)
        {
            bs.ptr = (bs.end - 1);
            bs.file_bytes = file_bytes;
            bs.file = file;
        }
        else
        {
            /* Strange to set an index to -1, but the very first call to getbit will iterate this */
            bs.buf_index = -1;
            bs.ptr = -1;
        }

        return bs;
    }

    public static function bs_read(bs : Bitstream) : Bitstream
    {
        if (bs.file_bytes > 0)
        {
            var bytes_read : Int = 0;
            var bytes_to_read : Int = 0;

            bytes_to_read = Defines.FILE_BYTES_SIZE;

            if (bytes_to_read > bs.file_bytes)
                bytes_to_read = bs.file_bytes;

            try
            {
                var buf = haxe.io.Bytes.alloc(bytes_to_read);
                var stream = bs.file;
                bytes_read = stream.readBytes(buf, 0, bytes_to_read);
                bs.buf_index = 0;
                for (i in 0 ... bytes_read)
                {
                    bs.buf[i] = buf.get(i);
                }
            }
            catch (err: Dynamic)
            {
                trace("Big error while reading file: " + err);
                bytes_read = 0;
            }

            if (bytes_read > 0)
            {
                bs.end = bytes_read;
                bs.file_bytes = bs.file_bytes - bytes_read;
            }
            else
            {
                for ( i in 0 ... Defines.FILE_BYTES_SIZE )
                {
                    bs.buf[i] = -1;
                }
                bs.error = 1;
            }
        }
        else
        {
            bs.error = 1;
            for ( i in 0 ... Defines.FILE_BYTES_SIZE )
            {
                bs.buf[i] = -1;
            }
        }

        bs.ptr = 0;
        bs.buf_index = 0;

        return bs;
    }

}
