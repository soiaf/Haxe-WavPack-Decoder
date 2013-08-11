/*
** UnpackUtils.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**
** Distributed under the BSD Software License (see license.txt)
**
*/

class UnpackUtils
{

    public function new()
    {
    }

    ///////////////////////////// executable code ////////////////////////////////

    // This function initializes everything required to unpack a WavPack block
    // and must be called before unpack_samples() is called to obtain audio data.
    // It is assumed that the WavpackHeader has been read into the wps.wphdr
    // (in the current WavpackStream). This is where all the metadata blocks are
    // scanned up to the one containing the audio bitstream.

public static function unpack_init(wpc : WavpackContext) : Int
    {
        var wps : WavpackStream = wpc.stream;
        var wpmd : WavpackMetadata = new WavpackMetadata();

        if (wps.wphdr.block_samples > 0 && wps.wphdr.block_index != -1)
            wps.sample_index = wps.wphdr.block_index;

        wps.mute_error = 0;
#if (!js)        
        wps.crc = 0xffffffff;
#end        
        wps.wvbits.sr = 0;

        while ((MetadataUtils.read_metadata_buff(wpc, wpmd)) == Defines.TRUE)
        {
            if ((MetadataUtils.process_metadata(wpc, wpmd)) == Defines.FALSE)
            {
                wpc.error = true;
                wpc.error_message = "invalid metadata!";
                return Defines.FALSE;
            }

            if (wpmd.id == Defines.ID_WV_BITSTREAM)
                break;
        }

        if (wps.wphdr.block_samples != 0 && (null == wps.wvbits.file) )
        {
            wpc.error_message = "invalid WavPack file!";
            wpc.error = true;
            return Defines.FALSE;
        }


        if (wps.wphdr.block_samples != 0)
        {
            if ((wps.wphdr.flags & Defines.INT32_DATA) != 0 && wps.int32_sent_bits != 0)
                wpc.lossy_blocks = 1;

            if ((wps.wphdr.flags & Defines.FLOAT_DATA) != 0
                    && (wps.float_flags & (Defines.FLOAT_EXCEPTIONS | Defines.FLOAT_ZEROS_SENT
                        | Defines.FLOAT_SHIFT_SENT | Defines.FLOAT_SHIFT_SAME)) != 0)
                wpc.lossy_blocks = 1;
        }

        wpc.error = false;
        wpc.stream = wps;
        return Defines.TRUE;
    }

    // This function initialzes the main bitstream for audio samples, which must
    // be in the "wv" file.

public static function init_wv_bitstream(wpc : WavpackContext, wpmd : WavpackMetadata) : Int
    {
        var wps : WavpackStream  = wpc.stream;

        if (wpmd.hasdata == Defines.TRUE)
            wps.wvbits = BitsUtils.bs_open_read(wpmd.data,  0, wpmd.byte_length, wpc.infile, 0, 0);
        else if (wpmd.byte_length > 0)
        {
            var len : Int = wpmd.byte_length & 1;
            wps.wvbits = BitsUtils.bs_open_read(wpc.read_buffer, -1,  wpc.read_buffer.length, wpc.infile,
            (wpmd.byte_length + len), 1);
        }

        return Defines.TRUE;
    }


    // Read decorrelation terms from specified metadata block into the
    // decorr_passes array. The terms range from -3 to 8, plus 17 & 18;
    // other values are reserved and generate errors for now. The delta
    // ranges from 0 to 7 with all values valid. Note that the terms are
    // stored in the opposite order in the decorr_passes array compared
    // to packing.

public static function read_decorr_terms(wps : WavpackStream, wpmd : WavpackMetadata) : Int
    {
        var termcnt : Int = wpmd.byte_length;
#if flash10
        var byteptr : flash.Vector < Int > = wpmd.data;
#else
        var byteptr : Array < Int > = wpmd.data;
#end
        var tmpwps : WavpackStream = new WavpackStream();

        var counter : Int = 0;
        var dcounter : Int = 0;

        if (termcnt > Defines.MAX_NTERMS)
            return Defines.FALSE;

        tmpwps.num_terms = termcnt;

        dcounter = termcnt - 1;

        for (i in 0 ... termcnt)
        {
            dcounter = termcnt - (i+1);
            tmpwps.decorr_passes[dcounter].term =  ( (byteptr[counter] & 0x1f) - 5);
            tmpwps.decorr_passes[dcounter].delta = ((byteptr[counter] >> 5) & 0x7);

            counter++;

            if (tmpwps.decorr_passes[dcounter].term < -3
            || (tmpwps.decorr_passes[dcounter].term > Defines.MAX_TERM && tmpwps.decorr_passes[dcounter].term < 17)
            || tmpwps.decorr_passes[dcounter].term > 18)
                return Defines.FALSE;
        }

        wps.decorr_passes = tmpwps.decorr_passes;
        wps.num_terms = tmpwps.num_terms;

        return Defines.TRUE;
    }


    // Read decorrelation weights from specified metadata block into the
    // decorr_passes array. The weights range +/-1024, but are rounded and
    // truncated to fit in signed chars for metadata storage. Weights are
    // separate for the two channels and are specified from the "last" term
    // (first during encode). Unspecified weights are set to zero.

public static function read_decorr_weights(wps : WavpackStream, wpmd : WavpackMetadata) : Int
    {
        var termcnt : Int = wpmd.byte_length;
        var tcount : Int;
#if flash10
        var byteptr : flash.Vector < Int > = wpmd.data;
#else
        var byteptr : Array < Int > = wpmd.data;
#end
        var dpp : DecorrPass = new DecorrPass();
        var counter : Int = 0;
        var dpp_idx : Int;
        var myiterator : Int = 0;
        var signedByte : Int = 0;

        if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
        {
            termcnt = termcnt >> 1;
        }

        if (termcnt > wps.num_terms)
        {
            return Defines.FALSE;
        }

        for ( tcount in 0 ... wps.num_terms )
        {
            dpp.weight_A = 0;
            dpp.weight_B = 0;
        }

        myiterator = wps.num_terms;

        while (termcnt > 0)
        {
            dpp_idx = myiterator - 1;
            signedByte = byteptr[counter];

            if(signedByte > 127)
            {
                signedByte = signedByte - 256;
            }
            dpp.weight_A =  WordsUtils.restore_weight(signedByte );

            wps.decorr_passes[dpp_idx].weight_A = dpp.weight_A;
            counter++;

            if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
            {
                signedByte = byteptr[counter];

                if(signedByte > 127)
                {
                    signedByte = signedByte - 256;
                }
                dpp.weight_B =  WordsUtils.restore_weight( signedByte );
                counter++;
            }
            wps.decorr_passes[dpp_idx].weight_B = dpp.weight_B;

            myiterator--;
            termcnt--;
        }

        return Defines.TRUE;
    }


    // Read decorrelation samples from specified metadata block into the
    // decorr_passes array. The samples are signed 32-bit values, but are
    // converted to signed log2 values for storage in metadata. Values are
    // stored for both channels and are specified from the "last" term
    // (first during encode) with unspecified samples set to zero. The
    // number of samples stored varies with the actual term value, so
    // those must obviously come first in the metadata.

public static function read_decorr_samples(wps : WavpackStream, wpmd : WavpackMetadata) : Int
    {
#if flash10
        var byteptr : flash.Vector < Int > = wpmd.data;
#else
        var byteptr : Array < Int > = wpmd.data;
#end
        var dpp : DecorrPass = new DecorrPass();
        var tcount : Int;
        var counter : Int = 0;
        var dpp_index : Int = 0;
        var uns_buf0 : Int;
        var uns_buf1 : Int;
        var uns_buf2 : Int;
        var uns_buf3 : Int;
        var signedTotal1 : Int;
        var signedTotal2 : Int;
        var sample_counter : Int = 0;

        dpp_index = 0;

        for ( i in 0 ... wps.num_terms)
        {
            tcount = wps.num_terms - (i + 1);

            dpp.term = wps.decorr_passes[dpp_index].term;

            for ( internalc in 0 ... Defines.MAX_TERM)
            {
                dpp.samples_A[internalc] = 0;
                dpp.samples_B[internalc] = 0;
                wps.decorr_passes[dpp_index].samples_A[internalc] = 0;
                wps.decorr_passes[dpp_index].samples_B[internalc] = 0;
            }

            dpp_index++;
        }

        if (wps.wphdr.version == 0x402 && (wps.wphdr.flags & Defines.HYBRID_FLAG) > 0)
        {
            counter += 2;

            if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
                counter += 2;
        }

        dpp_index--;

        while (counter < wpmd.byte_length)
        {
            if (dpp.term > Defines.MAX_TERM)
            {

                uns_buf0 = (byteptr[counter] & 0xff);
                uns_buf1 = (byteptr[counter + 1] & 0xff);
                uns_buf2 = (byteptr[counter + 2] & 0xff);
                uns_buf3 = (byteptr[counter + 3] & 0xff);

                // we now need to convert a 16 bit unsigned number to a 16 bit signed number

                signedTotal1 = uns_buf0 + (uns_buf1 << 8);
                if ( signedTotal1 > 32767)
                {
                    signedTotal1 = signedTotal1 - 65536;
                }

                signedTotal2 = uns_buf2 + (uns_buf3 << 8);
                if ( signedTotal2 > 32767)
                {
                    signedTotal2 = signedTotal2 - 65536;
                }

                dpp.samples_A[0] = WordsUtils.exp2s(signedTotal1);
                dpp.samples_A[1] = WordsUtils.exp2s(signedTotal2);
                counter += 4;

                if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
                {

                    uns_buf0 =  (byteptr[counter] & 0xff);
                    uns_buf1 =  (byteptr[counter + 1] & 0xff);
                    uns_buf2 =  (byteptr[counter + 2] & 0xff);
                    uns_buf3 =  (byteptr[counter + 3] & 0xff);

                    // we now need to convert a 16 bit unsigned number to a 16 bit signed number

                    signedTotal1 = uns_buf0 + (uns_buf1 << 8);
                    if ( signedTotal1 > 32767)
                    {
                        signedTotal1 = signedTotal1 - 65536;
                    }

                    signedTotal2 = uns_buf2 + (uns_buf3 << 8);
                    if ( signedTotal2 > 32767)
                    {
                        signedTotal2 = signedTotal2 - 65536;
                    }

                    dpp.samples_B[0] = WordsUtils.exp2s(signedTotal1);
                    dpp.samples_B[1] = WordsUtils.exp2s(signedTotal2);
                    counter += 4;
                }
            }
            else if (dpp.term < 0)
            {
                uns_buf0 =  (byteptr[counter] & 0xff);
                uns_buf1 =  (byteptr[counter + 1] & 0xff);
                uns_buf2 =  (byteptr[counter + 2] & 0xff);
                uns_buf3 =  (byteptr[counter + 3] & 0xff);

                // we now need to convert a 16 bit unsigned number to a 16 bit signed number

                signedTotal1 = uns_buf0 + (uns_buf1 << 8);
                if ( signedTotal1 > 32767)
                {
                    signedTotal1 = signedTotal1 - 65536;
                }

                signedTotal2 = uns_buf2 + (uns_buf3 << 8);
                if ( signedTotal2 > 32767)
                {
                    signedTotal2 = signedTotal2 - 65536;
                }


                dpp.samples_A[0] = WordsUtils.exp2s( signedTotal1 );
                dpp.samples_B[0] = WordsUtils.exp2s( signedTotal2 );

                counter += 4;
            }
            else
            {
                var m : Int = 0;
                var cnt : Int = dpp.term;

                while (cnt > 0)
                {
                    uns_buf0 =  (byteptr[counter] & 0xff);
                    uns_buf1 =  (byteptr[counter + 1] & 0xff);

                    // we now need to convert a 16 bit unsigned number to a 16 bit signed number

                    signedTotal1 = uns_buf0 + (uns_buf1 << 8);
                    if ( signedTotal1 > 32767)
                    {
                        signedTotal1 = signedTotal1 - 65536;
                    }

                    dpp.samples_A[m] = WordsUtils.exp2s( signedTotal1 );
                    counter += 2;

                    if ((wps.wphdr.flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) == 0)
                    {
                        uns_buf0 =  (byteptr[counter] & 0xff);
                        uns_buf1 =  (byteptr[counter + 1] & 0xff);

                        // we now need to convert a 16 bit unsigned number to a 16 bit signed number

                        signedTotal1 = uns_buf0 + (uns_buf1 << 8);
                        if ( signedTotal1 > 32767)
                        {
                            signedTotal1 = signedTotal1 - 65536;
                        }

                        dpp.samples_B[m] = WordsUtils.exp2s( signedTotal1 );
                        counter += 2;
                    }

                    m++;
                    cnt--;
                }
            }

            for ( sample_counter in 0 ... Defines.MAX_TERM )
            {
                wps.decorr_passes[dpp_index].samples_A[sample_counter] = dpp.samples_A[sample_counter];
                wps.decorr_passes[dpp_index].samples_B[sample_counter] = dpp.samples_B[sample_counter];
            }
            dpp_index--;
        }

        return Defines.TRUE;
    }


    // Read the int32 data from the specified metadata into the specified stream.
    // This data is used for integer data that has more than 24 bits of magnitude
    // or, in some cases, used to eliminate redundant bits from any audio stream.

public static function read_int32_info(wps : WavpackStream, wpmd : WavpackMetadata) : Int
    {
        var bytecnt : Int = wpmd.byte_length;
#if flash10
        var byteptr : flash.Vector < Int > = wpmd.data;
#else
        var byteptr : Array < Int > = wpmd.data;
#end
        var counter : Int = 0;

        if (bytecnt != 4)
            return Defines.FALSE; // should also return 0

        wps.int32_sent_bits = byteptr[counter];
        counter++;
        wps.int32_zeros = byteptr[counter];
        counter++;
        wps.int32_ones = byteptr[counter];
        counter++;
        wps.int32_dups = byteptr[counter];

        return Defines.TRUE;
    }


    // Read multichannel information from metadata. The first byte is the total
    // number of channels and the following bytes represent the channel_mask
    // as described for Microsoft WAVEFORMATEX.

public static function read_channel_info(wpc : WavpackContext, wpmd : WavpackMetadata) : Int
    {
        var bytecnt : Int = wpmd.byte_length;
        var shift : Int = 0;
#if flash10
        var byteptr : flash.Vector < Int > = wpmd.data;
#else
        var byteptr : Array < Int > = wpmd.data;
#end
        var counter : Int = 0;
        var mask : Int = 0;

        if (bytecnt == 0 || bytecnt > 5)
            return Defines.FALSE;

        wpc.config.num_channels = byteptr[counter];
        counter++;

        while (bytecnt >= 0)
        {
            mask |=((byteptr[counter] & 0xFF) << shift);
            counter++;
            shift += 8;
            bytecnt--;
        }

        wpc.config.channel_mask = mask;
        return Defines.TRUE;
    }

    // Read configuration information from metadata.

public static function read_config_info(wpc : WavpackContext, wpmd : WavpackMetadata) : Int
    {
        var bytecnt : Int = wpmd.byte_length;
#if flash10
        var byteptr : flash.Vector < Int > = wpmd.data;
#else
        var byteptr : Array < Int > = wpmd.data;
#end
        var counter : Int = 0;

        if (bytecnt >= 3)
        {
            wpc.config.flags &= 0xff;
            wpc.config.flags |= ((byteptr[counter] & 0xFF) << 8);
            counter++;
            wpc.config.flags |= ((byteptr[counter] & 0xFF) << 16);
            counter++;
            wpc.config.flags |= ((byteptr[counter] & 0xFF) << 24);
        }
        return Defines.TRUE;
    }

    // Read non-standard sampling rate from metadata.

public static function read_sample_rate(wpc : WavpackContext, wpmd : WavpackMetadata)
    {
        var bytecnt : Int = wpmd.byte_length;
#if flash10
        var byteptr : flash.Vector < Int > = wpmd.data;
#else
        var byteptr : Array < Int > = wpmd.data;
#end
        var counter : Int = 0;
        var sampleRate : Int = 0;

        if (bytecnt == 3)
        {
            sampleRate = (byteptr[counter] & 0xFF);
            counter++;
            sampleRate |= ((byteptr[counter] & 0xFF) << 8);
            counter++;
            sampleRate |= ((byteptr[counter] & 0xFF) << 16);
            wpc.config.sample_rate = sampleRate;
        }

        return Defines.TRUE;
    }


    // This monster actually unpacks the WavPack bitstream(s) into the specified
    // buffer as 32-bit integers or floats (depending on orignal data). Lossy
    // samples will be clipped to their original limits (i.e. 8-bit samples are
    // clipped to -128/+127) but are still returned in ints. It is up to the
    // caller to potentially reformat this for the final output including any
    // multichannel distribution, block alignment or endian compensation. The
    // function unpack_init() must have been called and the entire WavPack block
    // must still be visible (although wps.blockbuff will not be accessed again).
    // For maximum clarity, the function is broken up into segments that handle
    // various modes. This makes for a few extra infrequent flag checks, but
    // makes the code easier to follow because the nesting does not become so
    // deep. For maximum efficiency, the conversion is isolated to tight loops
    // that handle an entire buffer. The function returns the total number of
    // samples unpacked, which can be less than the number requested if an error
    // occurs or the end of the block is reached.

#if flash10
public function unpack_samples(wpc : WavpackContext, buffer : flash.Vector < Int >, sample_count : Float, bufferStartPos : Int) : Float
#else
public function unpack_samples(wpc : WavpackContext, buffer : Array < Int >, sample_count : Float, bufferStartPos : Int) : Float
#end
    {
        var wps : WavpackStream = wpc.stream;
        var flags : Int = wps.wphdr.flags;
        var crc : Int = wps.crc;
        var mute_limit : Int = ((1 << ((flags & Defines.MAG_MASK) >> Defines.MAG_LSB)) + 2);
        var dpp : DecorrPass;
        var tcount : Int = 0;
        var buffer_counter : Int = 0;

        var samples_processed : Int = 0;
        var myword = new WordsUtils();

        if (wps.sample_index + sample_count > wps.wphdr.block_index + wps.wphdr.block_samples)
            sample_count = wps.wphdr.block_index + wps.wphdr.block_samples - wps.sample_index;

        if (wps.mute_error > 0)
        {
            var tempc : Float = 0;

            if ((flags & Defines.MONO_FLAG) > 0)
            {
                tempc = sample_count;
            }
            else
            {
                tempc = 2 * sample_count;
            }

            buffer_counter = bufferStartPos;
            while (tempc > 0)
            {
                buffer[buffer_counter] = 0;
                tempc--;
                buffer_counter++;
            }

            wps.sample_index += sample_count;

            return sample_count;
        }

        if ((flags & Defines.HYBRID_FLAG) > 0)
            mute_limit *= 2;


        ///////////////////// handle version 4 mono data /////////////////////////

        if ((flags & (Defines.MONO_FLAG | Defines.FALSE_STEREO)) > 0)
        {
            var dpp_index : Int = 0;

            samples_processed = myword.get_words(sample_count, flags, wps.w, wps.wvbits, buffer, bufferStartPos);
            
            var sampleCountAsInt = Math.floor(sample_count);

            if(samples_processed==sampleCountAsInt)
            {
                for ( tcount in 0 ... wps.num_terms )
                {
                    dpp = wps.decorr_passes[dpp_index];
                    decorr_mono_pass(dpp, buffer, sample_count, bufferStartPos);

                    dpp_index++;
                }

                var bf_abs : Int  = 0;

                var crclimit : Int = sampleCountAsInt + bufferStartPos;
                for ( q in bufferStartPos ... crclimit )
                {
                    bf_abs = (buffer[q] < 0 ? -buffer[q] : buffer[q]);

                    if (bf_abs > mute_limit)
                    {
                        samples_processed = q;
                        break;
                    }
#if (!js)        
                    crc = crc * 3 + buffer[q];
#end                
                }
            }
        }

        //////////////////// handle version 4 stereo data ////////////////////////

        else
        {

            samples_processed = myword.get_words(sample_count, flags, wps.w, wps.wvbits, buffer, bufferStartPos);

            var sampleCountAsInt = Math.floor(sample_count);
            
            if(samples_processed==sampleCountAsInt)
            {
                if (sample_count < 16)
                {
                    var dpp_index : Int= 0;

                    for ( tcount in 0 ... wps.num_terms )
                    {
                        dpp = wps.decorr_passes[dpp_index];
                        decorr_stereo_pass(dpp, buffer, sample_count, bufferStartPos);
                        wps.decorr_passes[dpp_index] = dpp;
                        dpp_index++;
                    }
                }
                else
                {
                    var dpp_index : Int = 0;

                    for ( tcount in 0 ... wps.num_terms )
                    {
                        dpp = wps.decorr_passes[dpp_index];

                        decorr_stereo_pass(dpp, buffer, 8, bufferStartPos);

                        decorr_stereo_pass_cont(dpp, buffer, sample_count - 8, bufferStartPos + 16);

                        wps.decorr_passes[dpp_index] = dpp;

                        dpp_index++;
                    }
                }

                if ((flags & Defines.JOINT_STEREO) > 0)
                {
                    var bf_abs : Int = 0;
                    var bf1_abs : Int = 0;

                    for ( loopCounter in 0 ... sampleCountAsInt )
                    {
                        buffer_counter = (loopCounter * 2);
                        buffer[buffer_counter + 1 + bufferStartPos] = buffer[buffer_counter + 1 + bufferStartPos] - (buffer[buffer_counter + bufferStartPos] >> 1);
                        buffer[buffer_counter + bufferStartPos] = buffer[buffer_counter + bufferStartPos] + buffer[buffer_counter + 1 + bufferStartPos];


                        bf_abs = (buffer[buffer_counter + bufferStartPos] < 0 ? -buffer[buffer_counter + bufferStartPos] : buffer[buffer_counter + bufferStartPos]);
                        bf1_abs = (buffer[buffer_counter + 1 + bufferStartPos]
                        < 0
                        ? -buffer[buffer_counter + 1 + bufferStartPos]
                        : buffer[buffer_counter + 1 + bufferStartPos]);

                        if (bf_abs > mute_limit || bf1_abs > mute_limit)
                        {
                            samples_processed = Math.floor(buffer_counter / 2);
                            break;
                        }

#if (!js)
                        crc = (crc * 3 + buffer[buffer_counter + bufferStartPos]) * 3 + buffer[buffer_counter + 1 + bufferStartPos];
#end                    
                    }
                }
                else
                {
                    var bf_abs : Int = 0;
                    var bf1_abs : Int  = 0;

                    for ( loopCounter in 0 ... sampleCountAsInt )
                    {
                        buffer_counter = (loopCounter * 2);
                        bf_abs = (buffer[buffer_counter + bufferStartPos] < 0 ? -buffer[buffer_counter + bufferStartPos] : buffer[buffer_counter + bufferStartPos]);
                        bf1_abs = (buffer[buffer_counter + 1 + bufferStartPos]
                        < 0
                        ? -buffer[buffer_counter + 1 + bufferStartPos]
                        : buffer[buffer_counter + 1 + bufferStartPos]);

                        if (bf_abs > mute_limit || bf1_abs > mute_limit)
                        {
                            samples_processed = Math.floor(buffer_counter / 2);
                            break;
                        }
#if (!js)
                        crc = (crc * 3 + buffer[buffer_counter + bufferStartPos]) * 3 + buffer[buffer_counter + 1 + bufferStartPos];
#end                    
                    }
                }
            }
        }

        if (samples_processed != sample_count)
        {
            var sc : Float = 0;

            if ((flags & Defines.MONO_FLAG) > 0)
            {
                sc = sample_count;
            }
            else
            {
                sc = 2 * sample_count;
            }
            buffer_counter = bufferStartPos;

            while (sc > 0)
            {
                buffer[buffer_counter] = 0;
                sc--;
                buffer_counter++;
            }

            wps.mute_error = 1;
            samples_processed = Std.int(sample_count);
        }

        buffer = fixup_samples(wps, buffer, samples_processed, bufferStartPos);

        if ((flags & Defines.FALSE_STEREO) > 0)
        {
            var dest_idx : Int = (Math.floor(samples_processed) * 2) + bufferStartPos;
            var src_idx : Int = (Math.floor(samples_processed)) + bufferStartPos;
            var c : Int =  Math.floor(samples_processed);

            dest_idx--;
            src_idx--;

            while (c > 0)
            {
                buffer[dest_idx] = buffer[src_idx];
                dest_idx--;
                buffer[dest_idx] = buffer[src_idx];
                dest_idx--;
                src_idx--;
                c--;
            }
        }

        wps.sample_index += samples_processed;
#if (!js)        
        wps.crc = crc;
#else
        wps.crc = 0;
#end        

        return samples_processed;
    }

#if flash10
function decorr_stereo_pass(dpp : DecorrPass, buffer : flash.Vector < Int >, sample_count : Float, buf_idx : Int)
#else
function decorr_stereo_pass(dpp : DecorrPass, buffer : Array < Int >, sample_count : Float, buf_idx : Int)
#end
    {
        var delta : Int = dpp.delta;
        var deltaDouble : Int = 2 * delta;
        var weight_A : Int = dpp.weight_A;
        var weight_B : Int = dpp.weight_B;
        var sam_A : Int = 0;
        var sam_B : Int = 0;
        var m : Int = 0;
        var k : Int = 0;
        var bptr_counter : Int = 0;
        var sampleCountAsInt : Int = Math.floor(sample_count);
        var tempI : Int = 0;

        switch (dpp.term)
        {
        case 17:
            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + (i * 2);
                sam_A =  2 * dpp.samples_A[0] - dpp.samples_A[1];
                dpp.samples_A[1] = dpp.samples_A[0];

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                dpp.samples_A[0] =  tempI + buffer[bptr_counter];

                if (sam_A != 0 && buffer[bptr_counter] != 0)
                {
                    weight_A = weight_A + delta;
                    if ((sam_A ^ buffer[bptr_counter]) < 0)
                    {
                        weight_A = weight_A - deltaDouble;
                    }
                }

                buffer[bptr_counter] = dpp.samples_A[0];

                sam_A = 2 * dpp.samples_B[0] - dpp.samples_B[1];
                dpp.samples_B[1] = dpp.samples_B[0];

                tempI = (((((sam_A & 0xffff) * weight_B) >> 9) + (((sam_A & ~0xffff) >>9) * weight_B) + 1) >> 1);

                dpp.samples_B[0] = tempI + buffer[bptr_counter + 1];

                if (sam_A != 0 && buffer[bptr_counter + 1] != 0)
                {
                    weight_B = weight_B + delta;
                    if ((sam_A ^ buffer[bptr_counter + 1]) < 0)
                    {
                        weight_B = weight_B - deltaDouble;
                    }
                }

                buffer[bptr_counter + 1] = dpp.samples_B[0];
            }

        case 18:
            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + (i * 2);
                
                sam_A = (3 * dpp.samples_A[0] - dpp.samples_A[1]) >> 1;

                dpp.samples_A[1] = dpp.samples_A[0];

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                dpp.samples_A[0] =  tempI + buffer[bptr_counter];

                if (sam_A != 0 && buffer[bptr_counter] != 0)
                {
                    weight_A = weight_A + delta;
                    if ((sam_A ^ buffer[bptr_counter]) < 0)
                    {
                        weight_A = weight_A - deltaDouble;
                    }
                }

                buffer[bptr_counter] = dpp.samples_A[0];

                sam_A = (3 * dpp.samples_B[0] - dpp.samples_B[1]) >> 1;

                dpp.samples_B[1] = dpp.samples_B[0];

                tempI = (((((sam_A & 0xffff) * weight_B) >> 9) + (((sam_A & ~0xffff) >>9) * weight_B) + 1) >> 1);

                dpp.samples_B[0] =  tempI + buffer[bptr_counter + 1];

                if (sam_A != 0 && buffer[bptr_counter + 1] != 0)
                {
                    weight_B = weight_B + delta;
                    if ((sam_A ^ buffer[bptr_counter + 1]) < 0)
                    {
                        weight_B = weight_B - deltaDouble;
                    }
                }

                buffer[bptr_counter + 1] = dpp.samples_B[0];
            }

        case -1:
            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + (i * 2);

                tempI = (((((dpp.samples_A[0] & 0xffff) * weight_A) >> 9) + (((dpp.samples_A[0] & ~0xffff) >>9) * weight_A) + 1) >> 1);

                sam_A = buffer[bptr_counter] +  tempI;

                if ((dpp.samples_A[0] ^ buffer[bptr_counter]) < 0)
                {
                    if (dpp.samples_A[0] != 0 && buffer[bptr_counter] != 0 && (weight_A -= delta) < -1024)
                    {
                        weight_A = -1024;
                    }
                }
                else
                {
                    if (dpp.samples_A[0] != 0 && buffer[bptr_counter] != 0 && (weight_A += delta) > 1024)
                    {
                        weight_A = 1024;
                    }
                }

                buffer[bptr_counter] = sam_A;

                tempI = (((((sam_A & 0xffff) * weight_B) >> 9) + (((sam_A & ~0xffff) >>9) * weight_B) + 1) >> 1);

                dpp.samples_A[0] = buffer[bptr_counter + 1] +  tempI;

                if ((sam_A ^ buffer[bptr_counter + 1]) < 0)
                {
                    if (sam_A != 0 && buffer[bptr_counter + 1] != 0 && (weight_B -= delta) < -1024)
                    {
                        weight_B = -1024;
                    }
                }
                else
                {
                    if (sam_A != 0 && buffer[bptr_counter + 1] != 0 && (weight_B += delta) > 1024)
                    {
                        weight_B = 1024;
                    }
                }

                buffer[bptr_counter + 1] = dpp.samples_A[0];
            }

        case -2:
            sam_B = 0;
            sam_A = 0;

            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + (i * 2);

                tempI = (((((dpp.samples_B[0] & 0xffff) * weight_B) >> 9) + (((dpp.samples_B[0] & ~0xffff) >>9) * weight_B) + 1) >> 1);

                sam_B = buffer[bptr_counter + 1] +  tempI;

                if ((dpp.samples_B[0] ^ buffer[bptr_counter + 1]) < 0)
                {
                    if (dpp.samples_B[0] != 0 && buffer[bptr_counter + 1] != 0 && (weight_B -= delta) < -1024)
                    {
                        weight_B = -1024;
                    }
                }
                else
                {
                    if (dpp.samples_B[0] != 0 && buffer[bptr_counter + 1] != 0 && (weight_B += delta) > 1024)
                    {
                        weight_B = 1024;
                    }
                }

                buffer[bptr_counter + 1] = sam_B;

                tempI = (((((sam_B & 0xffff) * weight_A) >> 9) + (((sam_B & ~0xffff) >>9) * weight_A) + 1) >> 1);

                dpp.samples_B[0] = buffer[bptr_counter] +  tempI;

                if ((sam_B ^ buffer[bptr_counter]) < 0)
                {
                    if (sam_B != 0 && buffer[bptr_counter] != 0 && (weight_A -= delta) < -1024)
                    {
                        weight_A = -1024;
                    }
                }
                else
                {
                    if (sam_B != 0 && buffer[bptr_counter] != 0 && (weight_A += delta) > 1024)
                    {
                        weight_A = 1024;
                    }
                }
                buffer[bptr_counter] = dpp.samples_B[0];
            }

        case -3:
            sam_A = 0;

            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + (i * 2);

                tempI = (((((dpp.samples_A[0] & 0xffff) * weight_A) >> 9) + (((dpp.samples_A[0] & ~0xffff) >>9) * weight_A) + 1) >> 1);

                sam_A = buffer[bptr_counter] + tempI;

                if ((dpp.samples_A[0] ^ buffer[bptr_counter]) < 0)
                {
                    if (dpp.samples_A[0] != 0 && buffer[bptr_counter] != 0 && (weight_A -= delta) < -1024)
                    {
                        weight_A = -1024;
                    }
                }
                else
                {
                    if (dpp.samples_A[0] != 0 && buffer[bptr_counter] != 0 && (weight_A += delta) > 1024)
                    {
                        weight_A = 1024;
                    }
                }

                tempI = (((((dpp.samples_B[0] & 0xffff) * weight_B) >> 9) + (((dpp.samples_B[0] & ~0xffff) >>9) * weight_B) + 1) >> 1);

                sam_B = buffer[bptr_counter + 1] + tempI;

                if ((dpp.samples_B[0] ^ buffer[bptr_counter + 1]) < 0)
                {
                    if (dpp.samples_B[0] != 0 && buffer[bptr_counter + 1] != 0 && (weight_B -= delta) < -1024)
                    {
                        weight_B = -1024;
                    }
                }
                else
                {
                    if (dpp.samples_B[0] != 0 && buffer[bptr_counter + 1] != 0 && (weight_B += delta) > 1024)
                    {
                        weight_B = 1024;
                    }
                }

                dpp.samples_B[0] = sam_A;
                buffer[bptr_counter] = sam_A;
                dpp.samples_A[0] = sam_B;
                buffer[bptr_counter + 1] = sam_B;
            }

        default:
            sam_A = 0;
            m = 0;
            k = dpp.term & (Defines.MAX_TERM - 1);

            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + (i * 2);
                sam_A = dpp.samples_A[m];

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                dpp.samples_A[k] =  tempI + buffer[bptr_counter];

                if (sam_A != 0 && buffer[bptr_counter] != 0)
                {
                    weight_A = weight_A + delta;
                    if ((sam_A ^ buffer[bptr_counter]) < 0)
                    {
                        weight_A = weight_A - deltaDouble;
                    }
                }

                buffer[bptr_counter] = dpp.samples_A[k];

                sam_A = dpp.samples_B[m];

                tempI = (((((sam_A & 0xffff) * weight_B) >> 9) + (((sam_A & ~0xffff) >>9) * weight_B) + 1) >> 1);

                dpp.samples_B[k] =  tempI + buffer[bptr_counter + 1];

                if (sam_A != 0 && buffer[bptr_counter + 1] != 0)
                {
                    weight_B = weight_B + delta;
                    if ((sam_A ^ buffer[bptr_counter + 1]) < 0)
                    {
                        weight_B = weight_B - deltaDouble;
                    }
                }

                buffer[bptr_counter + 1] = dpp.samples_B[k];

                m = (m + 1) & (Defines.MAX_TERM - 1);
                k = (k + 1) & (Defines.MAX_TERM - 1);
            }

            if (m != 0)
            {
                var temp_samples : Array < Int > = new Array();
                temp_samples[Defines.MAX_TERM] = 0;       // pre-size the array, go slightly larger than needed

                for ( t in 0 ... dpp.samples_A.length )
                {
                    temp_samples[t] = dpp.samples_A[t];
                }

                for ( k in 0 ... Defines.MAX_TERM)
                {
                    dpp.samples_A[k] = temp_samples[m & (Defines.MAX_TERM - 1)];
                    m++;
                }

                for ( k in 0 ... Defines.MAX_TERM)
                {
                    temp_samples[k] = dpp.samples_B[k];
                }

                for ( k in 0 ... Defines.MAX_TERM)
                {
                    dpp.samples_B[k] = temp_samples[m & (Defines.MAX_TERM - 1)];
                    m++;
                }
            }

        }

        dpp.weight_A =  weight_A;
        dpp.weight_B =  weight_B;
    }

#if flash10
function decorr_stereo_pass_cont(dpp : DecorrPass, buffer : flash.Vector < Int >, sample_count : Float, buf_idx : Int)
#else
function decorr_stereo_pass_cont(dpp : DecorrPass, buffer : Array < Int >, sample_count : Float, buf_idx : Int)
#end
    {
        var delta : Int = dpp.delta;
        var weight_A : Int = dpp.weight_A;
        var weight_B : Int = dpp.weight_B;
        var tptr : Int = 0;
        var sam_A : Int = 0;
        var sam_B : Int = 0;
        var k : Int = 0;
        var i : Int = 0;
        var buffer_index : Int = buf_idx;
        var sampleCountAsInt : Int = Math.floor(sample_count);
        var tempI : Int = 0;

        switch (dpp.term)
        {
        case 17:
            for ( i in 0 ... sampleCountAsInt )
            {
                buffer_index = buf_idx + (i * 2);
                sam_A = 2 * buffer[buffer_index - 2] - buffer[buffer_index - 4];

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                buffer[buffer_index] =  tempI + (sam_B = buffer[buffer_index]);

                if (sam_A != 0 && sam_B != 0)
                    weight_A += (((sam_A ^ sam_B) >> 30) | 1) * delta;

                sam_A = 2 * buffer[buffer_index - 1] - buffer[buffer_index - 3];

                tempI = (((((sam_A & 0xffff) * weight_B) >> 9) + (((sam_A & ~0xffff) >>9) * weight_B) + 1) >> 1);

                buffer[buffer_index + 1] =  tempI + (sam_B = buffer[buffer_index + 1]);

                if (sam_A != 0 && sam_B != 0)
                    weight_B += (((sam_A ^ sam_B) >> 30) | 1) * delta;
            }

            buffer_index = buf_idx + (sampleCountAsInt * 2);
            dpp.samples_B[0] = buffer[buffer_index - 1];
            dpp.samples_A[0] = buffer[buffer_index - 2];
            dpp.samples_B[1] = buffer[buffer_index - 3];
            dpp.samples_A[1] = buffer[buffer_index - 4];

        case 18:
            for ( i in 0 ... sampleCountAsInt )
            {
                buffer_index = buf_idx + (i * 2);
                sam_A = (3 * buffer[buffer_index - 2] - buffer[buffer_index - 4]) >> 1;

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                buffer[buffer_index] =  tempI + (sam_B = buffer[buffer_index]);

                if (sam_A != 0 && sam_B != 0)
                    weight_A += (((sam_A ^ sam_B) >> 30) | 1) * delta;

                sam_A = (3 * buffer[buffer_index - 1] - buffer[buffer_index - 3]) >> 1;

                tempI = (((((sam_A & 0xffff) * weight_B) >> 9) + (((sam_A & ~0xffff) >>9) * weight_B) + 1) >> 1);

                buffer[buffer_index + 1] =  tempI + (sam_B = buffer[buffer_index + 1]);

                if (sam_A != 0 && sam_B != 0)
                    weight_B += (((sam_A ^ sam_B) >> 30) | 1) * delta;
            }
            buffer_index = buf_idx + (sampleCountAsInt * 2);

            dpp.samples_B[0] = buffer[buffer_index - 1];
            dpp.samples_A[0] = buffer[buffer_index - 2];
            dpp.samples_B[1] = buffer[buffer_index - 3];
            dpp.samples_A[1] = buffer[buffer_index - 4];

        case -1:
            for ( i in 0 ... sampleCountAsInt )
            {
                buffer_index = buf_idx + (i * 2);

                tempI = (((((buffer[buffer_index - 1] & 0xffff) * weight_A) >> 9) + (((buffer[buffer_index - 1] & ~0xffff) >>9) * weight_A) + 1) >> 1);

                buffer[buffer_index] =  tempI + (sam_A = buffer[buffer_index]);

                if ((buffer[buffer_index - 1] ^ sam_A) < 0)
                {
                    if (buffer[buffer_index - 1] != 0 && sam_A != 0 && (weight_A -= delta) < -1024)
                    {
                        weight_A = -1024;
                    }
                }
                else
                {
                    if (buffer[buffer_index - 1] != 0 && sam_A != 0 && (weight_A += delta) > 1024)
                    {
                        weight_A = 1024;
                    }
                }

                tempI = (((((buffer[buffer_index] & 0xffff) * weight_B) >> 9) + (((buffer[buffer_index] & ~0xffff) >>9) * weight_B) + 1) >> 1);

                buffer[buffer_index + 1] =  tempI + (sam_A = buffer[buffer_index + 1]);

                if ((buffer[buffer_index] ^ sam_A) < 0)
                {
                    if (buffer[buffer_index] != 0 && sam_A != 0 && (weight_B -= delta) < -1024)
                    {
                        weight_B = -1024;
                    }
                }
                else
                {
                    if (buffer[buffer_index] != 0 && sam_A != 0 && (weight_B += delta) > 1024)
                    {
                        weight_B = 1024;
                    }
                }
            }

            buffer_index = buf_idx + (sampleCountAsInt * 2);
            dpp.samples_A[0] = buffer[buffer_index - 1];

        case -2:
            sam_A = 0;
            sam_B = 0;

            for ( i in 0 ... sampleCountAsInt )
            {
                buffer_index = buf_idx + (i * 2);

                tempI = (((((buffer[buffer_index - 2] & 0xffff) * weight_B) >> 9) + (((buffer[buffer_index - 2] & ~0xffff) >>9) * weight_B) + 1) >> 1);

                buffer[buffer_index + 1] =  tempI + (sam_A = buffer[buffer_index + 1]);

                if ((buffer[buffer_index - 2] ^ sam_A) < 0)
                {
                    if (buffer[buffer_index - 2] != 0 && sam_A != 0 && (weight_B -= delta) < -1024)
                    {
                        weight_B = -1024;
                    }
                }
                else
                {
                    if (buffer[buffer_index - 2] != 0 && sam_A != 0 && (weight_B += delta) > 1024)
                    {
                        weight_B = 1024;
                    }
                }

                tempI = (((((buffer[buffer_index + 1] & 0xffff) * weight_A) >> 9) + (((buffer[buffer_index + 1] & ~0xffff) >>9) * weight_A) + 1) >> 1);

                buffer[buffer_index] =  tempI + (sam_A = buffer[buffer_index]);

                if ((buffer[buffer_index + 1] ^ sam_A) < 0)
                {
                    if (buffer[buffer_index + 1] != 0 && sam_A != 0 && (weight_A -= delta) < -1024)
                    {
                        weight_A = -1024;
                    }
                }
                else
                {
                    if (buffer[buffer_index + 1] != 0 && sam_A != 0 && (weight_A += delta) > 1024)
                    {
                        weight_A = 1024;
                    }
                }
            }

            buffer_index = buf_idx + (sampleCountAsInt * 2);
            dpp.samples_B[0] = buffer[buffer_index - 2];

        case -3:
            for ( i in 0 ... sampleCountAsInt )
            {
                buffer_index = buf_idx + (i * 2);

                tempI = (((((buffer[buffer_index - 1] & 0xffff) * weight_A) >> 9) + (((buffer[buffer_index - 1] & ~0xffff) >>9) * weight_A) + 1) >> 1);

                buffer[buffer_index] =  tempI + (sam_A = buffer[buffer_index]);

                if ((buffer[buffer_index - 1] ^ sam_A) < 0)
                {
                    if (buffer[buffer_index - 1] != 0 && sam_A != 0 && (weight_A -= delta) < -1024)
                    {
                        weight_A = -1024;
                    }
                }
                else
                {
                    if (buffer[buffer_index - 1] != 0 && sam_A != 0 && (weight_A += delta) > 1024)
                    {
                        weight_A = 1024;
                    }
                }

                tempI = (((((buffer[buffer_index - 2] & 0xffff) * weight_B) >> 9) + (((buffer[buffer_index - 2] & ~0xffff) >>9) * weight_B) + 1) >> 1);

                buffer[buffer_index + 1] =  tempI + (sam_A = buffer[buffer_index + 1]);

                if ((buffer[buffer_index - 2] ^ sam_A) < 0)
                {
                    if (buffer[buffer_index - 2] != 0 && sam_A != 0 && (weight_B -= delta) < -1024)
                    {
                        weight_B = -1024;
                    }
                }
                else
                {
                    if (buffer[buffer_index - 2] != 0 && sam_A != 0 && (weight_B += delta) > 1024)
                    {
                        weight_B = 1024;
                    }
                }
            }

            buffer_index = buf_idx + (sampleCountAsInt * 2);
            dpp.samples_A[0] = buffer[buffer_index - 1];
            dpp.samples_B[0] = buffer[buffer_index - 2];

        default:
            tptr = buf_idx - (dpp.term * 2);

            for ( i in 0 ... sampleCountAsInt )
            {
                buffer_index = buf_idx + (i * 2);

                tempI = (((((buffer[tptr] & 0xffff) * weight_A) >> 9) + (((buffer[tptr] & ~0xffff) >>9) * weight_A) + 1) >> 1);

                buffer[buffer_index] =  tempI + (sam_A = buffer[buffer_index]);

                if (buffer[tptr] != 0 && sam_A != 0)
                    weight_A += (((buffer[tptr] ^ sam_A) >> 30) | 1) * delta;

                tempI = (((((buffer[tptr + 1] & 0xffff) * weight_B) >> 9) + (((buffer[tptr + 1] & ~0xffff) >>9) * weight_B) + 1) >> 1);

                buffer[buffer_index + 1] =  tempI + (sam_A = buffer[buffer_index + 1]);

                if (buffer[tptr + 1] != 0 && sam_A != 0)
                    weight_B += (((buffer[tptr + 1] ^ sam_A) >> 30) | 1) * delta;

                tptr += 2;
            }

            buffer_index = buf_idx + (sampleCountAsInt * 2);
            buffer_index--;

            k = dpp.term - 1;
            i = 8;

            while( i > 0 )
            {
                i--;
                dpp.samples_B[k & (Defines.MAX_TERM - 1)] = buffer[buffer_index];
                buffer_index--;
                dpp.samples_A[k & (Defines.MAX_TERM - 1)] = buffer[buffer_index];
                buffer_index--;
                k--;
            }

        }

        dpp.weight_A =  weight_A;
        dpp.weight_B =  weight_B;
    }

#if flash10
public static function decorr_mono_pass(dpp : DecorrPass, buffer : flash.Vector < Int >, sample_count : Float, buf_idx : Int)
#else
public static function decorr_mono_pass(dpp : DecorrPass, buffer : Array < Int >, sample_count : Float, buf_idx : Int)
#end
    {
        var delta : Int = dpp.delta;
        var deltaDouble : Int = 2 * delta;
        var weight_A : Int = dpp.weight_A;
        var sam_A : Int = 0;
        var m : Int = 0;
        var k : Int  = 0;
        var bptr_counter : Int = 0;
        var sampleCountAsInt : Int = Math.floor(sample_count);
        var tempI : Int = 0;

        switch (dpp.term)
        {
        case 17:
            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + i;
                sam_A = 2 * dpp.samples_A[0] - dpp.samples_A[1];
                dpp.samples_A[1] = dpp.samples_A[0];

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                dpp.samples_A[0] =  tempI + buffer[bptr_counter];

                if (sam_A != 0 && buffer[bptr_counter] != 0)
                {
                    weight_A = weight_A + delta;
                    if ((sam_A ^ buffer[bptr_counter]) < 0)
                    {
                        weight_A = weight_A - deltaDouble;
                    }
                }
                buffer[bptr_counter] = dpp.samples_A[0];
            }

        case 18:
            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + i;
                sam_A = (3 * dpp.samples_A[0] - dpp.samples_A[1]) >> 1;
                dpp.samples_A[1] = dpp.samples_A[0];

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                dpp.samples_A[0] = tempI + buffer[bptr_counter];

                if (sam_A != 0 && buffer[bptr_counter] != 0)
                {
                    weight_A = weight_A + delta;
                    if ((sam_A ^ buffer[bptr_counter]) < 0)
                    {
                        weight_A = weight_A - deltaDouble;
                    }
                }
                buffer[bptr_counter] = dpp.samples_A[0];
            }

        default:
            m = 0;
            k = dpp.term & (Defines.MAX_TERM - 1);
            for ( i in 0 ... sampleCountAsInt )
            {
                bptr_counter = buf_idx + i;
                sam_A = dpp.samples_A[m];

                tempI = (((((sam_A & 0xffff) * weight_A) >> 9) + (((sam_A & ~0xffff) >>9) * weight_A) + 1) >> 1);

                dpp.samples_A[k] =  tempI + buffer[bptr_counter];

                if (sam_A != 0 && buffer[bptr_counter] != 0)
                {
                    weight_A = weight_A + delta;
                    if ((sam_A ^ buffer[bptr_counter]) < 0)
                    {
                        weight_A = weight_A - deltaDouble;
                    }
                }

                buffer[bptr_counter] = dpp.samples_A[k];
                m = (m + 1) & (Defines.MAX_TERM - 1);
                k = (k + 1) & (Defines.MAX_TERM - 1);
            }

            if (m != 0)
            {
                var temp_samples : Array < Int > = new Array();

                for ( temp in 0 ... Defines.MAX_TERM )
                {
                    temp_samples[temp] = dpp.samples_A[temp];
                }

                for ( k in 0 ... Defines.MAX_TERM )
                {
                    dpp.samples_A[k] = temp_samples[m & (Defines.MAX_TERM - 1)];
                    m++;
                }
            }

        }

        dpp.weight_A =  weight_A;
    }


    // This is a helper function for unpack_samples() that applies several final
    // operations.
    // If the extended integer data applies, then that operation is
    // executed first. If the unpacked data is lossy (and not corrected) then
    // it is clipped and shifted in a single operation. Otherwise, if it's
    // lossless then the last step is to apply the final shift (if any).

#if flash10
function fixup_samples(wps : WavpackStream, buffer : flash.Vector < Int >, sample_count : Float, bufferStartPos : Int) : flash.Vector < Int >
#else
function fixup_samples(wps : WavpackStream, buffer : Array < Int >, sample_count : Float, bufferStartPos : Int) : Array < Int >
#end
    {
        var flags : Int = wps.wphdr.flags;
        var shift : Int =  ((flags & Defines.SHIFT_MASK) >> Defines.SHIFT_LSB);
        
        if ((flags & Defines.FLOAT_DATA) != 0)
        {
            var sc : Float = 0;

            if ((flags & Defines.MONO_FLAG) != 0)
            {
                sc = sample_count;
            }
            else
            {
                sc = sample_count * 2;
            }

            buffer = FloatUtils.float_values(wps, buffer, sc, bufferStartPos);
        }

        if ((flags & Defines.INT32_DATA) != 0)
        {
            var sent_bits : Int = wps.int32_sent_bits;
            var zeros : Int = wps.int32_zeros;
            var ones : Int = wps.int32_ones;
            var dups : Int = wps.int32_dups;
            var buffer_counter : Int = bufferStartPos;

            var count : Float = 0;

            if ((flags & Defines.MONO_FLAG) != 0)
            {
                count = sample_count;
            }
            else
            {
                count = sample_count * 2;
            }

            if ((flags & Defines.HYBRID_FLAG) == 0 && sent_bits == 0 && (zeros + ones + dups) != 0)
            {
                while (count > 0)
                {
                    if (zeros != 0)
                        buffer[buffer_counter] <<= zeros;

                    else if (ones != 0)
                        buffer[buffer_counter] = ((buffer[buffer_counter] + 1) << ones) - 1;

                    else if (dups != 0)
                        buffer[buffer_counter] = ((buffer[buffer_counter] + (buffer[buffer_counter] & 1)) << dups)
                                                 - (buffer[buffer_counter] & 1);

                    buffer_counter++;
                    count--;
                }
            }
            else
                shift += zeros + sent_bits + ones + dups;
        }

        if ((flags & Defines.HYBRID_FLAG) != 0)
        {
            var min_value : Int = 0;
            var max_value : Int = 0;
            var min_shifted : Int = 0;
            var max_shifted : Int = 0;
            var buffer_counter : Int = bufferStartPos;
            
            switch ((flags & Defines.BYTES_STORED))
            {
            case 0:
                min_shifted = (min_value = -128 >> shift) << shift;
                max_shifted = (max_value = 127 >> shift) << shift;

            case 1:
                min_shifted = (min_value = -32768 >> shift) << shift;
                max_shifted = (max_value = 32767 >> shift) << shift;

            case 2:
                min_shifted = (min_value = -8388608 >> shift) << shift;
                max_shifted = (max_value = 8388607 >> shift) << shift;

            case 3:
            default:
                min_shifted = (min_value =  0x80000000 >> shift) << shift;
                max_shifted = (max_value =  0x7FFFFFFF >> shift) << shift;
            }

            if ((flags & Defines.MONO_FLAG) == 0)
                sample_count *= 2;

            while (sample_count > 0)
            {
                if (buffer[buffer_counter] < min_value)
                    buffer[buffer_counter] = min_shifted;

                else if (buffer[buffer_counter] > max_value)
                    buffer[buffer_counter] = max_shifted;

                else
                    buffer[buffer_counter] <<= shift;

                buffer_counter++;
                sample_count--;
            }
        }
        else if (shift != 0)
        {
            var buffer_counter : Int = bufferStartPos;

            if ((flags & Defines.MONO_FLAG) == 0)
                sample_count *= 2;

            while (sample_count > 0)
            {
                buffer[buffer_counter] = buffer[buffer_counter] << shift;
                buffer_counter++;
                sample_count--;
            }
        }

        return buffer;
    }


    // This function checks the crc value(s) for an unpacked block, returning the
    // number of actual crc errors detected for the block. The block must be
    // completely unpacked before this test is valid. For losslessly unpacked
    // blocks of float or extended integer data the extended crc is also checked.
    // Note that WavPack's crc is not a CCITT approved polynomial algorithm, but
    // is a much simpler method that is virtually as robust for real world data.

public static function check_crc_error(wpc : WavpackContext) : Int
    {
        var wps : WavpackStream = wpc.stream;
        var result : Int = 0;

#if (!js)        
        if (wps.crc != wps.wphdr.crc)
        {
            ++result;
        }
#end        

        return result;
    }
}
