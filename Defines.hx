/*
** Defines.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class Defines
{
    // Change the following value to an even number to reflect the maximum number of samples to be processed
    // per call to WavPackUtils.WavpackUnpackSamples. The Flash player code works best with a value of 8192
    // while the neko code works better with smaller values, for example 256

    #if flash10
        public static inline var SAMPLE_BUFFER_SIZE : Int = 8192;
	#elseif js
		public static inline var SAMPLE_BUFFER_SIZE : Int = 44100;
    #else
        public static inline var SAMPLE_BUFFER_SIZE : Int = 256;
    #end

    // The following is the maximum amount of bytes read from the file 'per read'

    public static inline var FILE_BYTES_SIZE : Int = 1024;

    public static inline var WPC_READ_BUFFER_LENGTH : Int = FILE_BYTES_SIZE;

    public static inline var FALSE : Int = 0;
    public static inline var TRUE : Int = 1;

    // or-values for "flags"

    public static inline var BYTES_STORED : Int = 3;       // 1-4 bytes/sample
    public static inline var MONO_FLAG : Int  = 4;       // not stereo
    public static inline var HYBRID_FLAG : Int = 8;       // hybrid mode

    public static inline var FALSE_STEREO : Int = 0x40000000;      // block is stereo, but data is mono

    public static inline var SHIFT_LSB : Int = 13;
    public static inline var SHIFT_MASK : Int = (0x1f << SHIFT_LSB);

    public static inline var FLOAT_DATA : Int  = 0x80;    // ieee 32-bit floating point data

    public static inline var SRATE_LSB : Int = 23;
    public static inline var SRATE_MASK : Int = (0xf << SRATE_LSB);

    public static inline var FINAL_BLOCK : Int = 0x1000;  // final block of multichannel segment

    public static inline var MIN_STREAM_VERS : Int = 0x402;       // lowest stream version we'll decode
    public static inline var MAX_STREAM_VERS : Int = 0x410;       // highest stream version we'll decode

    public static inline var ID_DUMMY : Int            =    0x0;
    public static inline var ID_ENCODER_INFO : Int     =    0x1;
    public static inline var ID_DECORR_TERMS : Int     =    0x2;
    public static inline var ID_DECORR_WEIGHTS : Int   =    0x3;
    public static inline var ID_DECORR_SAMPLES : Int   =    0x4;
    public static inline var ID_ENTROPY_VARS : Int     =    0x5;
    public static inline var ID_HYBRID_PROFILE : Int   =    0x6;
    public static inline var ID_SHAPING_WEIGHTS : Int  =    0x7;
    public static inline var ID_FLOAT_INFO : Int       =    0x8;
    public static inline var ID_INT32_INFO : Int       =    0x9;
    public static inline var ID_WV_BITSTREAM : Int     =    0xa;
    public static inline var ID_WVC_BITSTREAM : Int    =    0xb;
    public static inline var ID_WVX_BITSTREAM : Int    =    0xc;
    public static inline var ID_CHANNEL_INFO : Int     =    0xd;

    public static inline var JOINT_STEREO : Int  =  0x10;    // joint stereo
    public static inline var CROSS_DECORR : Int  =  0x20;    // no-delay cross decorrelation
    public static inline var HYBRID_SHAPE : Int  =  0x40;    // noise shape (hybrid mode only)

    public static inline var INT32_DATA : Int     = 0x100;   // special extended int handling
    public static inline var HYBRID_BITRATE : Int = 0x200;   // bitrate noise (hybrid mode only)
    public static inline var HYBRID_BALANCE : Int = 0x400;   // balance noise (hybrid stereo mode only)

    public static inline var INITIAL_BLOCK : Int  = 0x800;   // initial block of multichannel segment

    public static inline var FLOAT_SHIFT_ONES : Int = 1;      // bits left-shifted into float = '1'
    public static inline var FLOAT_SHIFT_SAME : Int = 2;      // bits left-shifted into float are the same
    public static inline var FLOAT_SHIFT_SENT : Int = 4;      // bits shifted into float are sent literally
    public static inline var FLOAT_ZEROS_SENT : Int = 8;      // "zeros" are not all real zeros
    public static inline var FLOAT_NEG_ZEROS : Int  = 0x10;   // contains negative zeros
    public static inline var FLOAT_EXCEPTIONS : Int = 0x20;   // contains exceptions (inf, nan, etc.)

    public static inline var ID_OPTIONAL_DATA : Int    =  0x20;
    public static inline var ID_ODD_SIZE : Int         =  0x40;
    public static inline var ID_LARGE : Int            =  0x80;

    public static inline var MAX_NTERMS : Int = 16;
    public static inline var MAX_TERM : Int = 8;

    public static inline var MAG_LSB : Int = 18;
    public static inline var MAG_MASK : Int = (0x1f << MAG_LSB);

    public static inline var ID_RIFF_HEADER : Int   = 0x21;
    public static inline var ID_RIFF_TRAILER : Int  = 0x22;
    public static inline var ID_REPLAY_GAIN : Int   = 0x23;
    public static inline var ID_CUESHEET : Int      = 0x24;
    public static inline var ID_CONFIG_BLOCK : Int  = 0x25;
    public static inline var ID_MD5_CHECKSUM : Int  = 0x26;
    public static inline var ID_SAMPLE_RATE : Int   = 0x27;

    public static inline var CONFIG_BYTES_STORED : Int    = 3;       // 1-4 bytes/sample
    public static inline var CONFIG_MONO_FLAG : Int       = 4;       // not stereo
    public static inline var CONFIG_HYBRID_FLAG : Int     = 8;       // hybrid mode
    public static inline var CONFIG_JOINT_STEREO : Int    = 0x10;    // joint stereo
    public static inline var CONFIG_CROSS_DECORR : Int    = 0x20;    // no-delay cross decorrelation
    public static inline var CONFIG_HYBRID_SHAPE : Int    = 0x40;    // noise shape (hybrid mode only)
    public static inline var CONFIG_FLOAT_DATA : Int      = 0x80;    // ieee 32-bit floating point data
    public static inline var CONFIG_FAST_FLAG : Int       = 0x200;   // fast mode
    public static inline var CONFIG_HIGH_FLAG : Int       = 0x800;   // high quality mode
    public static inline var CONFIG_VERY_HIGH_FLAG : Int  = 0x1000;  // very high
    public static inline var CONFIG_BITRATE_KBPS : Int    = 0x2000;  // bitrate is kbps, not bits / sample
    public static inline var CONFIG_AUTO_SHAPING : Int    = 0x4000;  // automatic noise shaping
    public static inline var CONFIG_SHAPE_OVERRIDE : Int  = 0x8000;  // shaping mode specified
    public static inline var CONFIG_JOINT_OVERRIDE : Int  = 0x10000; // joint-stereo mode specified
    public static inline var CONFIG_CREATE_EXE : Int      = 0x40000; // create executable
    public static inline var CONFIG_CREATE_WVC : Int      = 0x80000; // create correction file
    public static inline var CONFIG_OPTIMIZE_WVC : Int    = 0x100000; // maximize bybrid compression
    public static inline var CONFIG_CALC_NOISE : Int      = 0x800000; // calc noise in hybrid mode
    public static inline var CONFIG_LOSSY_MODE : Int      = 0x1000000; // obsolete (for information)
    public static inline var CONFIG_EXTRA_MODE : Int      = 0x2000000; // extra processing mode
    public static inline var CONFIG_SKIP_WVX : Int        = 0x4000000; // no wvx stream w/ floats & big ints
    public static inline var CONFIG_MD5_CHECKSUM : Int    = 0x8000000; // compute & store MD5 signature
//    public static inline var CONFIG_OPTIMIZE_MONO : Float   = 0x80000000; // optimize for mono streams posing as stereo

    public static inline var MODE_WVC : Int        = 0x1;
    public static inline var MODE_LOSSLESS : Int   = 0x2;
    public static inline var MODE_HYBRID : Int     = 0x4;
    public static inline var MODE_FLOAT : Int      = 0x8;
    public static inline var MODE_VALID_TAG : Int  = 0x10;
    public static inline var MODE_HIGH : Int       = 0x20;
    public static inline var MODE_FAST : Int       = 0x40;

    public function new()
    {  
    }
}
