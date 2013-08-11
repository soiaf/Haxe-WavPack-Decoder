/*
** WordsUtils.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class WordsUtils
{

    //////////////////////////////// local macros /////////////////////////////////

    static inline var LIMIT_ONES : Int = 16; // maximum consecutive 1s sent for "div" data

    // these control the time constant "slow_level" which is used for hybrid mode
    // that controls bitrate as a function of residual level (HYBRID_BITRATE).
    static inline var SLS : Int = 8;
    static inline var SLO : Int = ((1 << (SLS - 1)));


    // these control the time constant of the 3 median level breakpoints
    static inline var DIV0 : Int = 128; // 5/7 of samples
    static inline var DIV1 : Int = 64;  // 10/49 of samples
    static inline var DIV2 : Int = 32;  // 20/343 of samples
    
    
    ///////////////////////////// local table storage ////////////////////////////

    static var nbits_table : Array < Int > = 
    [
    0, 1, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 4, 4, 4, 4,     // 0 - 15
    5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5,     // 16 - 31
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,     // 32 - 47
    6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6,     // 48 - 63
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,     // 64 - 79
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,     // 80 - 95
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,     // 96 - 111
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,     // 112 - 127
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,     // 128 - 143
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,     // 144 - 159
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,     // 160 - 175
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,     // 176 - 191
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,     // 192 - 207
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,     // 208 - 223
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,     // 224 - 239
    8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8         // 240 - 255
    ].concat([8]);
    
    
    static var log2_table : Array < Int > = 
    [
    0x00, 0x01, 0x03, 0x04, 0x06, 0x07, 0x09, 0x0a, 0x0b, 0x0d, 0x0e, 0x10, 0x11, 0x12, 0x14, 0x15,
    0x16, 0x18, 0x19, 0x1a, 0x1c, 0x1d, 0x1e, 0x20, 0x21, 0x22, 0x24, 0x25, 0x26, 0x28, 0x29, 0x2a,
    0x2c, 0x2d, 0x2e, 0x2f, 0x31, 0x32, 0x33, 0x34, 0x36, 0x37, 0x38, 0x39, 0x3b, 0x3c, 0x3d, 0x3e,
    0x3f, 0x41, 0x42, 0x43, 0x44, 0x45, 0x47, 0x48, 0x49, 0x4a, 0x4b, 0x4d, 0x4e, 0x4f, 0x50, 0x51,
    0x52, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a, 0x5c, 0x5d, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63,
    0x64, 0x66, 0x67, 0x68, 0x69, 0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x74, 0x75,
    0x76, 0x77, 0x78, 0x79, 0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85,
    0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92, 0x93, 0x94, 0x95,
    0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4,
    0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf, 0xb0, 0xb1, 0xb2, 0xb2,
    0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf, 0xc0, 0xc0,
    0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcb, 0xcc, 0xcd, 0xce,
    0xcf, 0xd0, 0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd8, 0xd9, 0xda, 0xdb,
    0xdc, 0xdc, 0xdd, 0xde, 0xdf, 0xe0, 0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe4, 0xe5, 0xe6, 0xe7, 0xe7,
    0xe8, 0xe9, 0xea, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xee, 0xef, 0xf0, 0xf1, 0xf1, 0xf2, 0xf3, 0xf4,
    0xf4, 0xf5, 0xf6, 0xf7, 0xf7, 0xf8, 0xf9, 0xf9, 0xfa, 0xfb, 0xfc, 0xfc, 0xfd, 0xfe, 0xff
    ].concat([0xff]);


    static var exp2_table : Array < Int > = 
    [
    0x00, 0x01, 0x01, 0x02, 0x03, 0x03, 0x04, 0x05, 0x06, 0x06, 0x07, 0x08, 0x08, 0x09, 0x0a, 0x0b,
    0x0b, 0x0c, 0x0d, 0x0e, 0x0e, 0x0f, 0x10, 0x10, 0x11, 0x12, 0x13, 0x13, 0x14, 0x15, 0x16, 0x16,
    0x17, 0x18, 0x19, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1d, 0x1e, 0x1f, 0x20, 0x20, 0x21, 0x22, 0x23,
    0x24, 0x24, 0x25, 0x26, 0x27, 0x28, 0x28, 0x29, 0x2a, 0x2b, 0x2c, 0x2c, 0x2d, 0x2e, 0x2f, 0x30,
    0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3a, 0x3a, 0x3b, 0x3c, 0x3d,
    0x3e, 0x3f, 0x40, 0x41, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x48, 0x49, 0x4a, 0x4b,
    0x4c, 0x4d, 0x4e, 0x4f, 0x50, 0x51, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5a,
    0x5b, 0x5c, 0x5d, 0x5e, 0x5e, 0x5f, 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
    0x6a, 0x6b, 0x6c, 0x6d, 0x6e, 0x6f, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79,
    0x7a, 0x7b, 0x7c, 0x7d, 0x7e, 0x7f, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x87, 0x88, 0x89, 0x8a,
    0x8b, 0x8c, 0x8d, 0x8e, 0x8f, 0x90, 0x91, 0x92, 0x93, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b,
    0x9c, 0x9d, 0x9f, 0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad,
    0xaf, 0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbc, 0xbd, 0xbe, 0xbf, 0xc0,
    0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc8, 0xc9, 0xca, 0xcb, 0xcd, 0xce, 0xcf, 0xd0, 0xd2, 0xd3, 0xd4,
    0xd6, 0xd7, 0xd8, 0xd9, 0xdb, 0xdc, 0xdd, 0xde, 0xe0, 0xe1, 0xe2, 0xe4, 0xe5, 0xe6, 0xe8, 0xe9,
    0xea, 0xec, 0xed, 0xee, 0xf0, 0xf1, 0xf2, 0xf4, 0xf5, 0xf6, 0xf8, 0xf9, 0xfa, 0xfc, 0xfd
    ].concat([0xff]);


    static var ones_count_table : Array < Int > = 
    [
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,5,
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,6,
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,5,
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,7,
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,5,
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,6,
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,5,
    0,1,0,2,0,1,0,3,0,1,0,2,0,1,0,4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
    ].concat([8]);



    ///////////////////////////// executable code ////////////////////////////////

    public function new()
    {
   
    }

    // Read the median log2 values from the specifed metadata structure, convert
    // them back to 32-bit unsigned values and store them. If length is not
    // exactly correct then we flag and return an error.

    public static function read_entropy_vars(wps : WavpackStream, wpmd : WavpackMetadata) : Int
    {
        #if flash10
            var byteptr : flash.Vector < Int > = wpmd.data;
        #else
            var byteptr : Array < Int > = wpmd.data;
        #end
        var b_array : Array < Int > = new Array();
        var i : Int = 0;
        var w : WordsData = new WordsData();

        for ( i in 0 ... 6 )
        {
            b_array[i] = (byteptr[i] & 0xff);
        }

        w.holding_one = 0;
        w.holding_zero = 0;

        if (wpmd.byte_length != 12)
        {
            if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
            {
                return Defines.FALSE;
            }
        }

        w.c[0].median[0] = exp2s(b_array[0] + (b_array[1] << 8));
        w.c[0].median[1] = exp2s(b_array[2] + (b_array[3] << 8));
        w.c[0].median[2] = exp2s(b_array[4] + (b_array[5] << 8));
 
        if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
        {
            for ( i in 6 ... 12 )
            {
                b_array[i] = (byteptr[i] & 0xff);
            }
            w.c[1].median[0] = exp2s(b_array[6] + (b_array[7] << 8));
            w.c[1].median[1] = exp2s(b_array[8] + (b_array[9] << 8));
            w.c[1].median[2] = exp2s(b_array[10] + (b_array[11] << 8));            
        }

        wps.w = w;

        return Defines.TRUE;
    }


    // Read the hybrid related values from the specifed metadata structure, convert
    // them back to their internal formats and store them. The extended profile
    // stuff is not implemented yet, so return an error if we get more data than
    // we know what to do with.

    public static function read_hybrid_profile(wps : WavpackStream, wpmd : WavpackMetadata) : Int
    {
        #if flash10
            var byteptr : flash.Vector < Int > = wpmd.data;
        #else
            var byteptr : Array < Int > = wpmd.data;
        #end
        var bytecnt : Int = wpmd.byte_length;
        var buffer_counter : Int = 0;
        var uns_buf : Int = 0;
        var uns_buf_plusone : Int = 0;

        if ((wps.wphdr.flags & Defines.HYBRID_BITRATE) != 0)
        {
            uns_buf =  (byteptr[buffer_counter] & 0xff);
            uns_buf_plusone =  (byteptr[buffer_counter + 1] & 0xff);

            wps.w.c[0].slow_level = exp2s(uns_buf + (uns_buf_plusone << 8));
            buffer_counter = buffer_counter + 2;

            if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
            {
                uns_buf =  (byteptr[buffer_counter] & 0xff);
                uns_buf_plusone =  (byteptr[buffer_counter + 1] & 0xff);
                wps.w.c[1].slow_level = exp2s(uns_buf + (uns_buf_plusone << 8));
                buffer_counter = buffer_counter + 2;
            }
        }

        uns_buf =  (byteptr[buffer_counter] & 0xff);
        uns_buf_plusone =  (byteptr[buffer_counter + 1] & 0xff);

        wps.w.bitrate_acc[0] =  (uns_buf + (uns_buf_plusone << 8)) << 16;
        buffer_counter = buffer_counter + 2;

        if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
        {
            uns_buf =  (byteptr[buffer_counter] & 0xff);
            uns_buf_plusone =  (byteptr[buffer_counter + 1] & 0xff);

            wps.w.bitrate_acc[1] =  (uns_buf + (uns_buf_plusone << 8)) << 16;
            buffer_counter = buffer_counter + 2;
        }

        if (buffer_counter < bytecnt)
        {
            uns_buf =  (byteptr[buffer_counter] & 0xff);
            uns_buf_plusone =  (byteptr[buffer_counter + 1] & 0xff);

            wps.w.bitrate_delta[0] = exp2s( (uns_buf + (uns_buf_plusone << 8)));
            buffer_counter = buffer_counter + 2;

            if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
            {
                uns_buf =  (byteptr[buffer_counter] & 0xff);
                uns_buf_plusone =  (byteptr[buffer_counter + 1] & 0xff);
                wps.w.bitrate_delta[1] = exp2s((uns_buf + (uns_buf_plusone << 8)));
                buffer_counter = buffer_counter + 2;
            }

            if (buffer_counter < bytecnt)
                return Defines.FALSE;
        }
        else
        {
            wps.w.bitrate_delta[0] = 0; 
            wps.w.bitrate_delta[1] = 0;         
        }

        return Defines.TRUE;
    }

    // This function is called during both encoding and decoding of hybrid data to
    // update the "error_limit" variable which determines the maximum sample error
    // allowed in the main bitstream. In the HYBRID_BITRATE mode (which is the only
    // currently implemented) this is calculated from the slow_level values and the
    // bitrate accumulators. Note that the bitrate accumulators can be changing.

    public static function update_error_limit(w : WordsData, flags : Int, notmono : Bool) : WordsData
    {
        w.bitrate_acc[0] = w.bitrate_acc[0] + w.bitrate_delta[0];
        var bitrate_0 : Int = ( (w.bitrate_acc[0]) >> 16);

        if ( !notmono )        //mono or false stereo
        {     
            if ((flags & Defines.HYBRID_BITRATE) != 0)
            {             
                var slow_log_0 : Int = (( w.c[0].slow_level + SLO) >> SLS);

                if (slow_log_0 - bitrate_0 > -0x100)
                    w.c[0].error_limit = exp2s(slow_log_0 - bitrate_0 + 0x100);
                else
                    w.c[0].error_limit = 0;
            }
            else
            {             
                w.c[0].error_limit = exp2s(bitrate_0);
            }
        }
        else
        {         
            w.bitrate_acc[1] += w.bitrate_delta[1];
            var bitrate_1 : Int = ( w.bitrate_acc[1]  >> 16);

            if ((flags & Defines.HYBRID_BITRATE) != 0)
            {
                var slow_log_0 : Int =  ( (w.c[0].slow_level + SLO) >> SLS);
                var slow_log_1 : Int = ( (w.c[1].slow_level + SLO) >> SLS);

                if ((flags & Defines.HYBRID_BALANCE) != 0)
                {
                    var balance : Int = (slow_log_1 - slow_log_0 + bitrate_1 + 1) >> 1;

                    if (balance > bitrate_0)
                    {
                        bitrate_1 = bitrate_0 * 2;
                        bitrate_0 = 0;
                    }
                    else if (-balance > bitrate_0)
                    {
                        bitrate_0 = bitrate_0 * 2;
                        bitrate_1 = 0;
                    }
                    else
                    {
                        bitrate_1 = bitrate_0 + balance;
                        bitrate_0 = bitrate_0 - balance;
                    }
                }

                if (slow_log_0 - bitrate_0 > -0x100)
                    w.c[0].error_limit = exp2s(slow_log_0 - bitrate_0 + 0x100);
                else
                    w.c[0].error_limit = 0;

                if (slow_log_1 - bitrate_1 > -0x100)
                    w.c[1].error_limit = exp2s(slow_log_1 - bitrate_1 + 0x100);
                else
                    w.c[1].error_limit = 0;
            }
            else
            {             
                w.c[0].error_limit = exp2s(bitrate_0);
                w.c[1].error_limit = exp2s(bitrate_1);
            }
        }

        return w;
    }


    // Read the next word from the bitstream "wvbits" and return the value. This
    // function can be used for hybrid or lossless streams, but since an
    // optimized version is available for lossless this function would normally
    // be used for hybrid only. If a hybrid lossless stream is being read then
    // the "correction" offset is written at the specified pointer. A return value
    // of WORD_EOF indicates that the end of the bitstream was reached (all 1s) or
    // some other error occurred.

    #if flash10
    public function get_words(nsamples : Float, flags : Int, w : WordsData, bs : Bitstream, buffer : flash.Vector< Int >, bufferStartPos : Int) : Int
    #else
    public function get_words(nsamples : Float, flags : Int, w : WordsData, bs : Bitstream, buffer : Array< Int >, bufferStartPos : Int) : Int
    #end
    {
        var c : Array < EntropyData >  = w.c;
        var csamples : Int = 0;
        var buffer_counter : Int = bufferStartPos;
        var entidx : Int = 1;
        var nsamplesAsInt : Int = 0;
        var samplesProcessed : Int = 0;
        var mask : Int = 0;
        var cbits : Int = 0;
        var ones_count : Int = 0;
        var low : Int = 0;
        var mid : Int = 0;
        var high : Int = 0;
        var notmono : Bool;
        
        notmono = false;
        
        if ((flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0) // if not mono
        {
            notmono = true;
        }
        
        if ( notmono ) // if not mono
        {
            nsamples *= 2;
        }
        else
        {
            // it is mono
            entidx = 0;
        }
 
        nsamplesAsInt = Math.floor(nsamples);
        for ( csamples in 0 ... nsamplesAsInt )
        {

            ones_count = 0;
            low = 0;
            mid = 0;
            high = 0;
          
            samplesProcessed = samplesProcessed + 1;

            if ( notmono ) // if not mono
            {
                entidx = 1 - entidx;    // swaps between 0 and 1 - if entidx is 1 it becomes 0, if 0 becomes 1
            }

            if ((w.c[0].median[0] & ~1) == 0 && w.holding_zero == 0 && w.holding_one == 0
                && (w.c[1].median[0] & ~1) == 0)
            {

                if (w.zeros_acc > 0)
                {
                    --w.zeros_acc;

                    if (w.zeros_acc > 0)
                    {
                        c[entidx].slow_level -= (c[entidx].slow_level + SLO) >> SLS;
                        buffer[buffer_counter] = 0;
                        buffer_counter++;                       
                        continue;
                    }
                }
                else
                {
                    cbits = 0;
                    BitsUtils.getbit(bs);

                    while (cbits < 33 && bs.bitval > 0)
                    {
                        cbits++;
                        BitsUtils.getbit(bs);
                    }

                    if (cbits == 33)
                    {
                        break;
                    }

                    if (cbits < 2)
                        w.zeros_acc = cbits;
                    else
                    {

                        --cbits;
                        mask = 1;
                        w.zeros_acc = 0;

                        while(cbits > 0 )
                        {
                            BitsUtils.getbit(bs);

                            if (bs.bitval > 0)
                            {
                                w.zeros_acc = (w.zeros_acc) | (mask);
                            }
                            mask = mask * 2;
                            cbits--;
                        }
                        w.zeros_acc = (w.zeros_acc) | (mask);
                    }

                    if (w.zeros_acc > 0)
                    {

                        c[entidx].slow_level -= (c[entidx].slow_level + SLO) >> SLS;
                        w.c[0].median[0] = 0;
                        w.c[0].median[1] = 0;
                        w.c[0].median[2] = 0;
                        w.c[1].median[0] = 0;
                        w.c[1].median[1] = 0;
                        w.c[1].median[2] = 0;

                        buffer[buffer_counter] = 0;
                        buffer_counter++;                       
                        continue;
                    }
                }
            }

            if (w.holding_zero > 0)
                ones_count = w.holding_zero = 0;
            else
            {
                var next8 : Int = 0;
                var uns_buf : Int = 0;

                if (bs.bc < 8)
                {

                    bs.ptr++;
                    bs.buf_index++;

                    if (bs.ptr == bs.end)
                        BitsUtils.bs_read(bs);

                    uns_buf = (bs.buf[bs.buf_index] & 0xff);

                    bs.sr = bs.sr | (uns_buf << bs.bc); // values in buffer must be unsigned

                    next8 = (bs.sr & 0xff);

                    bs.bc += 8;
                }
                else
                {
                    next8 = (bs.sr & 0xff);
                }
                
                if (next8 == 0xff)
                {

                    bs.bc -= 8;
                    bs.sr >>= 8;

                    ones_count = 8;
                    BitsUtils.getbit(bs);

                    while (ones_count < (LIMIT_ONES + 1) && bs.bitval > 0)
                    {
                        ones_count++;
                        BitsUtils.getbit(bs);
                    }

                    if (ones_count == (LIMIT_ONES + 1))
                    {                    
                        break;
                    }

                    if (ones_count == LIMIT_ONES)
                    {
                        mask = 0;
                        cbits = 0;
                        BitsUtils.getbit(bs);

                        while (cbits < 33 && bs.bitval > 0)
                        {
                            cbits++;
                            BitsUtils.getbit(bs);
                        }

                        if (cbits == 33)
                        {
                            break;
                        }

                        if (cbits < 2)
                            ones_count = cbits;
                        else
                        {
                            mask = 1;
                            ones_count = 0;
                            cbits--;
                            while(cbits > 0)
                            {
                                cbits--;
                                BitsUtils.getbit(bs);

                                if (bs.bitval > 0)
                                    ones_count = (ones_count) | (mask);    
                                 mask = (mask) << 1;
                            }
                            ones_count = (ones_count) | (mask);
                        }

                        ones_count += LIMIT_ONES;
                    }
                }
                else
                {
                    ones_count = ones_count_table[next8];
                    bs.bc = bs.bc - ( (ones_count) + 1);
                    bs.sr = bs.sr >> ones_count + 1; // needs to be unsigned
                }

                if (w.holding_one > 0)
                {
                    w.holding_one = (ones_count) & 1;
                    ones_count = ((ones_count) >> 1) + 1;
                }
                else
                {
                    w.holding_one = (ones_count) & 1;
                    ones_count = (ones_count) >> 1;
                }

                w.holding_zero = (~w.holding_one & 1);
            }

            if ((flags & Defines.HYBRID_FLAG) != 0
                && ( !notmono || (csamples & 1) == 0))
                w = update_error_limit(w, flags, notmono);

            if (ones_count == 0)
            {
                low = 0;
                high = (((c[entidx].median[0] ) >> 4) + 1) - 1;
                c[entidx].median[0] -= (((c[entidx].median[0] + (DIV0 - 2)) >> 7) * 2);               
            }
            else
            {
                low = ((( c[entidx].median[0] ) >> 4) + 1);   
                c[entidx].median[0] += ((c[entidx].median[0] + DIV0) >> 7) * 5;                
                
                if (ones_count == 1)
                {            
                    high = low + (( c[entidx].median[1]  >> 4) + 1) - 1;
                    c[entidx].median[1] -= ((c[entidx].median[1] + (DIV1 - 2)) >> 6) * 2;
                }
                else
                {
                    low += (( c[entidx].median[1] >> 4) + 1);
                    c[entidx].median[1] += ((c[entidx].median[1] + DIV1) >> 6) * 5;

                    if (ones_count == 2)
                    {                   
                        high = low + (( c[entidx].median[2] >> 4) + 1) - 1;
                        c[entidx].median[2] -= ((c[entidx].median[2] + (DIV2 - 2)) >> 5) * 2;
                    }
                    else
                    {
                        low += (ones_count - 2) * (( (c[entidx].median[2]) >> 4) + 1);
                        high = low + (( c[entidx].median[2] >> 4) + 1) - 1;
                        c[entidx].median[2] += ((c[entidx].median[2] + DIV2) >> 5) * 5;
                    }
                }
            }

            mid = (high + low + 1) >> 1;

            if (c[entidx].error_limit == 0)
            {           
                mid = read_code(bs, high - low);

                mid = mid + low;
            }
            else
                while (high - low > c[entidx].error_limit)
                {

                    BitsUtils.getbit(bs);
                    
                    if (bs.bitval > 0)
                    {
                        mid = (high + (low = mid) + 1) >> 1;
                    }
                    else
                    {
                        mid = ((high = mid - 1) + low + 1) >> 1;
                    }                   
                }

            BitsUtils.getbit(bs);

            if (bs.bitval > 0)
            {
                buffer[buffer_counter] = ~mid;
            }
            else
            {
                buffer[buffer_counter] =  mid;
            }

            buffer_counter++;

            if ((flags & Defines.HYBRID_BITRATE) != 0)
            {          
                c[entidx].slow_level = c[entidx].slow_level - ( (c[entidx].slow_level + SLO) >> SLS) + mylog2(mid);               
            }
        }

        w.c = c;

        if ( !notmono )
        {       
            return samplesProcessed;
        }
        else
        {
            return (samplesProcessed >> 1);
        }
    }

    function count_bits(av : Int) : Int
    {
        if (av < 256 )                // 1 << 8
        {
            return nbits_table[av];
        }
        else
        {
            if (av < 65536)           // 1 << 16
            {
                return nbits_table[(av >>> 8)] + 8;
            }
            else
            {
                if (av < 16777216 )      // 1 << 24
                {
                    return nbits_table[(av >>> 16)] + 16;
                }
                else
                {
                    return nbits_table[(av >>> 24)] + 24;
                }
            }
        }
    }    


    // Read a single unsigned value from the specified bitstream with a value
    // from 0 to maxcode. If there are exactly a power of two number of possible
    // codes then this will read a fixed number of bits; otherwise it reads the
    // minimum number of bits and then determines whether another bit is needed
    // to define the code.

    function read_code(bs : Bitstream, maxcode : Int) : Int
    {   
        var bitcount : Int = count_bits(maxcode);
        var extras : Int = (1 << bitcount) - maxcode - 1;
        var code : Int = 0;

        if (bitcount == 0)
        {
            return (0);
        }

        code = BitsUtils.getbits(bitcount - 1, bs);

        code = code & ((1 << (bitcount - 1)) - 1);

        if (code >= extras)
        {

            code = (code << 1) - extras;

            BitsUtils.getbit(bs);

            if (bs.bitval > 0)
                ++code;
        }

        return (code);
    }


    // The concept of a base 2 logarithm is used in many parts of WavPack. It is
    // a way of sufficiently accurately representing 32-bit signed and unsigned
    // values storing only 16 bits (actually fewer). It is also used in the hybrid
    // mode for quickly comparing the relative magnitude of large values (i.e.
    // division) and providing smooth exponentials using only addition.

    // These are not strict logarithms in that they become linear around zero and
    // can therefore represent both zero and negative values. They have 8 bits
    // of precision and in "roundtrip" conversions the total error never exceeds 1
    // part in 225 except for the cases of +/-115 and +/-195 (which error by 1).


    // This function returns the log2 for the specified 32-bit unsigned value.
    // The maximum value allowed is about 0xff800000 and returns 8447.

    public static function mylog2(avalue : Int) : Int
    {
        var dbits : Int = 0;

        avalue += avalue >> 9;
        if ( avalue < (1 << 8))
        {
            dbits = nbits_table[ avalue];
            return (dbits << 8) + log2_table[ (avalue << (9 - dbits)) & 0xff];
        }
        else
        {
            if (avalue < (1 << 16))
            {
                dbits = nbits_table[ (avalue >> 8)] + 8;
            }

            else if (avalue < (1 << 24))
            {
                dbits = nbits_table[ (avalue >> 16)] + 16;
            }

            else
            {
                dbits = nbits_table[ (avalue >> 24)] + 24;
            }
            return (dbits << 8) + log2_table[ (avalue >> (dbits - 9)) & 0xff];
        }
    }    


    // This function returns the log2 for the specified 32-bit signed value.
    // All input values are valid and the return values are in the range of
    // +/- 8192.

    public static function log2s(value : Int) : Int
    {
        if (value < 0)
        {
            return -mylog2(-value);
        }
        else
        {
            return mylog2(value);
        }
    }


    // This function returns the original integer represented by the supplied
    // logarithm (at least within the provided accuracy). The log is signed,
    // but since a full 32-bit value is returned this can be used for unsigned
    // conversions as well (i.e. the input range is -8192 to +8447).

    public static function exp2s(log : Int) : Int
    {
        var value : Int;

        if (log < 0)
            return -exp2s(-log);

        value = exp2_table[log & 0xff] | 0x100;

        if ((log >>= 8) <= 9)
            return ( (value >> (9 - log)));
        else
            return ( (value << (log - 9)));
    }


    // These two functions convert internal weights (which are normally +/-1024)
    // to and from an 8-bit signed character version for storage in metadata. The
    // weights are clipped here in the case that they are outside that range.

    public static function restore_weight(weight : Int) : Int
    {
        var result : Int;

        if ((result = weight << 3) > 0)
            result += (result + 64) >> 7;

        return result;
    }

}
