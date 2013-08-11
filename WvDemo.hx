/*
** WvDemo.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class WvDemo
{
    static var temp_buffer : Array < Int > = new Array();
	static var pcmBuffer : Array < Int > = new Array();

    public static function main()	
    {
        var FormatChunkHeader : ChunkHeader = new ChunkHeader();
        var DataChunkHeader : ChunkHeader = new ChunkHeader();
        var myRiffChunkHeader : RiffChunkHeader = new RiffChunkHeader();
        var WaveHeader : WaveHeader = new WaveHeader();

        var myRiffChunkHeaderAsByteArray : Array < Int > = new Array();
        var myRiffChunkHeaderAsBytes = haxe.io.Bytes.alloc(12);
        var myFormatChunkHeaderAsByteArray : Array < Int > = new Array();
        var myFormatChunkHeaderAsBytes = haxe.io.Bytes.alloc(8);   
        var myDataChunkHeaderAsByteArray : Array < Int > = new Array();
        var myDataChunkHeaderAsBytes = haxe.io.Bytes.alloc(8);   
        var myWaveHeaderAsByteArray : Array < Int > = new Array();
        var myWaveHeaderAsBytes = haxe.io.Bytes.alloc(16);

        var pcmBufferAsBytes = haxe.io.Bytes.alloc(4 * Defines.SAMPLE_BUFFER_SIZE);    

        var total_unpacked_samples : Float = 0;
        var total_samples : Int = 0;
        var num_channels : Int  = 0;
        var bps : Int = 0;
        var wpc : WavpackContext = new WavpackContext();

        var start : Float = 0;
        var end : Float = 0;

        var inputWVFile : String = Sys.args()[0];

        if (inputWVFile == null)
        {
            inputWVFile = "input.wv";
        }

        var fstream = sys.io.File.read(inputWVFile,true);

        try
        {
             wpc = WavPackUtils.WavpackOpenFileInput(fstream);
        }
        catch (err: Dynamic)
        {
            Sys.println("Input file not found");
            var es = haxe.CallStack.exceptionStack();
            Sys.println(haxe.CallStack.toString(es));
            Sys.exit(1);
        }

        if (wpc.error)
        {
            Sys.println("Sorry an error has occured");
            Sys.println(wpc.error_message);
            Sys.exit(1);
        }

        num_channels = WavPackUtils.WavpackGetReducedChannels(wpc);

        trace("The wavpack file has " + num_channels + " channels");

        total_samples = Math.floor(WavPackUtils.WavpackGetNumSamples(wpc));

        trace("The wavpack file has " + total_samples + " samples");

        bps = WavPackUtils.WavpackGetBytesPerSample(wpc);

        trace("The wavpack file has " + bps + " bytes per sample");

        myRiffChunkHeader.ckID[0] = 82;    // R
        myRiffChunkHeader.ckID[1] = 73;    // I
        myRiffChunkHeader.ckID[2] = 70;    // F
        myRiffChunkHeader.ckID[3] = 70;    // F

        myRiffChunkHeader.ckSize = (total_samples * num_channels * bps + 8 * 2 + 16 + 4);
        myRiffChunkHeader.formType[0] = 87;    // W
        myRiffChunkHeader.formType[1] = 65;    // A
        myRiffChunkHeader.formType[2] = 86;    // V
        myRiffChunkHeader.formType[3] = 69;    // E

        FormatChunkHeader.ckID[0] = 102;    // f
        FormatChunkHeader.ckID[1] = 109;    // m
        FormatChunkHeader.ckID[2] = 116;    // t
        FormatChunkHeader.ckID[3] = 32;    // ' ' (space)

        FormatChunkHeader.ckSize = 16;

        WaveHeader.FormatTag = 1;
        WaveHeader.NumChannels = num_channels;
        WaveHeader.SampleRate = WavPackUtils.WavpackGetSampleRate(wpc);
        WaveHeader.BlockAlign = num_channels * bps;
        WaveHeader.BytesPerSecond = WaveHeader.SampleRate * WaveHeader.BlockAlign;
        WaveHeader.BitsPerSample = WavPackUtils.WavpackGetBitsPerSample(wpc);

        DataChunkHeader.ckID[0] = 100;  // d
        DataChunkHeader.ckID[1] = 97;  // a
        DataChunkHeader.ckID[2] = 116;  // t
        DataChunkHeader.ckID[3] = 97;  // a
        DataChunkHeader.ckSize = (total_samples * num_channels * bps);

        myRiffChunkHeaderAsByteArray[0] =  myRiffChunkHeader.ckID[0];
        myRiffChunkHeaderAsByteArray[1] =  myRiffChunkHeader.ckID[1];
        myRiffChunkHeaderAsByteArray[2] =  myRiffChunkHeader.ckID[2];
        myRiffChunkHeaderAsByteArray[3] =  myRiffChunkHeader.ckID[3];

        // swap endians here

        myRiffChunkHeaderAsByteArray[7] =  (myRiffChunkHeader.ckSize >>> 24);
        myRiffChunkHeaderAsByteArray[6] =  (myRiffChunkHeader.ckSize >>> 16);
        myRiffChunkHeaderAsByteArray[5] =  (myRiffChunkHeader.ckSize >>> 8);
        myRiffChunkHeaderAsByteArray[4] =  myRiffChunkHeader.ckSize;

        myRiffChunkHeaderAsByteArray[8] =  myRiffChunkHeader.formType[0];
        myRiffChunkHeaderAsByteArray[9] =  myRiffChunkHeader.formType[1];
        myRiffChunkHeaderAsByteArray[10] =  myRiffChunkHeader.formType[2];
        myRiffChunkHeaderAsByteArray[11] =  myRiffChunkHeader.formType[3];
        
        for(i in 0 ... 12)
        {
            myRiffChunkHeaderAsBytes.set(i,myRiffChunkHeaderAsByteArray[i]);
        }    

        myFormatChunkHeaderAsByteArray[0] =  FormatChunkHeader.ckID[0];
        myFormatChunkHeaderAsByteArray[1] =  FormatChunkHeader.ckID[1];
        myFormatChunkHeaderAsByteArray[2] =  FormatChunkHeader.ckID[2];
        myFormatChunkHeaderAsByteArray[3] =  FormatChunkHeader.ckID[3];

        // swap endians here
        myFormatChunkHeaderAsByteArray[7] =  (FormatChunkHeader.ckSize >>> 24);
        myFormatChunkHeaderAsByteArray[6] =  (FormatChunkHeader.ckSize >>> 16);
        myFormatChunkHeaderAsByteArray[5] =  (FormatChunkHeader.ckSize >>> 8);
        myFormatChunkHeaderAsByteArray[4] =  (FormatChunkHeader.ckSize);
        
        for(i in 0 ... 8)
        {
            myFormatChunkHeaderAsBytes.set(i,myFormatChunkHeaderAsByteArray[i]);
        }          

        // swap endians
        myWaveHeaderAsByteArray[1] =  (WaveHeader.FormatTag >>> 8);
        myWaveHeaderAsByteArray[0] =  (WaveHeader.FormatTag);

        // swap endians
        myWaveHeaderAsByteArray[3] =  (WaveHeader.NumChannels >>> 8);
        myWaveHeaderAsByteArray[2] =  WaveHeader.NumChannels;


        // swap endians
        myWaveHeaderAsByteArray[7] =  (Math.floor(WaveHeader.SampleRate) >>> 24);
        myWaveHeaderAsByteArray[6] =  (Math.floor(WaveHeader.SampleRate) >>> 16);
        myWaveHeaderAsByteArray[5] =  (Math.floor(WaveHeader.SampleRate) >>> 8);
        myWaveHeaderAsByteArray[4] =  (Math.floor(WaveHeader.SampleRate));

        // swap endians

        myWaveHeaderAsByteArray[11] =  (Math.floor(WaveHeader.BytesPerSecond) >>> 24);
        myWaveHeaderAsByteArray[10] =  (Math.floor(WaveHeader.BytesPerSecond) >>> 16);
        myWaveHeaderAsByteArray[9] =  (Math.floor(WaveHeader.BytesPerSecond) >>> 8);
        myWaveHeaderAsByteArray[8] =  Math.floor(WaveHeader.BytesPerSecond);

        // swap endians
        myWaveHeaderAsByteArray[13] =  (WaveHeader.BlockAlign >>> 8);
        myWaveHeaderAsByteArray[12] =  WaveHeader.BlockAlign;

        // swap endians
        myWaveHeaderAsByteArray[15] =  (WaveHeader.BitsPerSample >>> 8);
        myWaveHeaderAsByteArray[14] =  WaveHeader.BitsPerSample;
        
        for(i in 0 ... 16)
        {
            myWaveHeaderAsBytes.set(i,myWaveHeaderAsByteArray[i]);
        }          

        myDataChunkHeaderAsByteArray[0] =  DataChunkHeader.ckID[0];
        myDataChunkHeaderAsByteArray[1] =  DataChunkHeader.ckID[1];
        myDataChunkHeaderAsByteArray[2] =  DataChunkHeader.ckID[2];
        myDataChunkHeaderAsByteArray[3] =  DataChunkHeader.ckID[3];

        // swap endians

        myDataChunkHeaderAsByteArray[7] =  (DataChunkHeader.ckSize >>> 24);
        myDataChunkHeaderAsByteArray[6] =  (DataChunkHeader.ckSize >>> 16);
        myDataChunkHeaderAsByteArray[5] =  (DataChunkHeader.ckSize >>> 8);
        myDataChunkHeaderAsByteArray[4] =  (DataChunkHeader.ckSize);

        for(i in 0 ... 8)
        {
            myDataChunkHeaderAsBytes.set(i,myDataChunkHeaderAsByteArray[i]);
        } 

        try
        {
            var samples_unpacked : Float;
            var fostream = sys.io.File.write("output.wav",true);
            var bytesToWrite : Int = 0;
            var samples_to_unpack : Float = 0;
            fostream.writeBytes(myRiffChunkHeaderAsBytes,0,12);
            fostream.writeBytes(myFormatChunkHeaderAsBytes,0,8);
            fostream.writeBytes(myWaveHeaderAsBytes,0,16);
            fostream.writeBytes(myDataChunkHeaderAsBytes,0,8);
            
            samples_to_unpack = Defines.SAMPLE_BUFFER_SIZE / num_channels;
            temp_buffer[Math.floor(samples_to_unpack)] = 0;                                       // pre-size the array (one more than needed)
            pcmBuffer[4 * Defines.SAMPLE_BUFFER_SIZE] = 0;                                        // pre-size the array (one more than needed)

            var currentDate : Date = Date.now();

            start = currentDate.getTime();

            while (true)
            {

                samples_unpacked = WavPackUtils.WavpackUnpackSamples(wpc, temp_buffer, samples_to_unpack);

                total_unpacked_samples += samples_unpacked;

                if (samples_unpacked > 0)
                {
                    samples_unpacked = samples_unpacked * num_channels;

                    format_samples(bps, temp_buffer, samples_unpacked);	// formatted and results placed in pcmBuffer
                    
                    bytesToWrite = Math.floor(samples_unpacked) * bps;
                    
                    for(i in 0 ... bytesToWrite)
                    {
                         pcmBufferAsBytes.set(i,pcmBuffer[i]);
                    } 
                    fostream.writeBytes(pcmBufferAsBytes,0,bytesToWrite);
                }

                if (samples_unpacked == 0)
                    break;

            } // end of while

            currentDate = Date.now();
            
            end = currentDate.getTime();

            Sys.println(end - start + " milli seconds to process WavPack file in main loop");

            fostream.close();
        }
        catch (err: Dynamic)
        {
            var es = haxe.CallStack.exceptionStack();
            Sys.println(haxe.CallStack.toString(es));
            Sys.println("Error when writing wav file, sorry: ");           
            Sys.exit(1);
        }

        if ((WavPackUtils.WavpackGetNumSamples(wpc) != -1)
            && (total_unpacked_samples != WavPackUtils.WavpackGetNumSamples(wpc)))
        {
            Sys.println("Incorrect number of samples");
            Sys.exit(1);
        }

        if (WavPackUtils.WavpackGetNumErrors(wpc) > 0)
        {
            Sys.println("CRC errors detected");
            Sys.exit(1);
        }

        Sys.exit(0);

    }


    // Reformat samples from longs in processor's native endian mode to
    // little-endian data with (possibly) less than 4 bytes / sample.

    public static function format_samples(bps : Int, src : Array < Int >, samcnt : Float) : Void
    {
        var temp : Int = 0;
        var counter : Int = 0;
        var counter2 : Int = 0;

        switch (bps)
        {
            case 1:
                while (samcnt > 0)
                {
                    pcmBuffer[counter] =  (0x00FF & (src[counter] + 128));
                    counter++;
                    samcnt--;
                }

            case 2:
                while (samcnt > 0)
                {
                    temp = src[counter2];
                    pcmBuffer[counter] =  temp;
                    counter++;
                    pcmBuffer[counter] =  (temp >>> 8);
                    counter++;
                    counter2++;
                    samcnt--;
                }

            case 3:
                while (samcnt > 0)
                {
                    temp = src[counter2];
                    pcmBuffer[counter] =  temp;
                    counter++;
                    pcmBuffer[counter] =  (temp >>> 8);
                    counter++;
                    pcmBuffer[counter] =  (temp >>> 16);
                    counter++;
                    counter2++;
                    samcnt--;
                }

            case 4:
                while (samcnt > 0)
                {
                    temp = src[counter2];
                    pcmBuffer[counter] =  temp;
                    counter++;
                    pcmBuffer[counter] =  (temp >>> 8);
                    counter++;
                    pcmBuffer[counter] =  (temp >>> 16);
                    counter++;
                    pcmBuffer[counter] =  (temp >>> 24);
                    counter++;
                    counter2++;
                    samcnt--;
                }

        }

    }

}
