/*
** TestFlash.hx
**
** Copyright (c) 2008 - 2013 Peter McQuillan
**
** All Rights Reserved.
**                       
** Distributed under the BSD Software License (see license.txt)  
**
*/

class TestFlash
{
    static var s : flash.media.Sound;
    var sch : flash.media.SoundChannel;
    var total_unpacked_samples : Float;
    static var num_channels : Int;
    static var bps : Int;

    static var mc : flash.display.MovieClip;
    static var stage : Dynamic; 
    static var playBtn : flash.display.Sprite;
    static var stopBtn : flash.display.Sprite;
    static var te : flash.text.TextField;


    var fr : flash.net.FileReference;

    //File types which we want the user to open 

    private static var FILE_TYPES : Array <flash.net.FileFilter> = [new flash.net.FileFilter("WavPack File", "*.wv;*.WV")]; 

    static var wpc : WavpackContext;


    private function onLoadComplete(e: flash.events.Event) : Void 
    {
        te.text = "File loaded\n";
        te.text = te.text + "total num of bytes in WavPack file " + fr.size + "\n";

        var filebytes = haxe.io.Bytes.ofData(fr.data);  
        var total_samples : Int = 0;
        var num_samples : Float = 0;
        var sampleRate : Float;
        var duration : Int = 0;

        fr = null;

        var bistream = new haxe.io.BytesInput(filebytes, 0);

        try
        {
             wpc = WavPackUtils.WavpackOpenFileInput(bistream);
        }
        catch (err: Dynamic)
        {
            trace("Input file not found");
            var es = haxe.CallStack.exceptionStack();
            trace(haxe.CallStack.toString(es));
        }

        if (wpc.error)
        {
            te.text = te.text + "Sorry an error has occured\n";
            te.text = te.text + wpc.error_message + "\n";
            te.text = te.text + "Please select a new WavPack file";
          
            playBtn.visible = true;
            stopBtn.visible = false;
        }
        else
        {	
            num_channels = WavPackUtils.WavpackGetReducedChannels(wpc);

            te.text = te.text + "The wavpack file has " + num_channels + " channels\n";

            total_samples = Math.floor(WavPackUtils.WavpackGetNumSamples(wpc));

            te.text = te.text + "The wavpack file has " + total_samples + " samples\n";

            total_unpacked_samples = 0;

            sampleRate = WavPackUtils.WavpackGetSampleRate(wpc);

            if(sampleRate != 44100)
            {
                te.text = te.text + "The sample rate for this file is " + sampleRate + "\n";
                te.text = te.text + "Please note that this sample rate is not supported and\n";
                te.text = te.text + "your file will not be played back correctly\n";
            }
        
	    num_samples = WavPackUtils.WavpackGetNumSamples (wpc);
	    duration = Math.floor(num_samples/sampleRate);

            te.text = te.text + "The length of time for the song is " + duration + " seconds\n";

            bps = WavPackUtils.WavpackGetBytesPerSample(wpc);

            if(bps != 2 && bps!= 3)
            {
                te.text = te.text + "Sorry, but this Flash demo player only supports 16-bit and 24-bit\n";
                te.text = te.text + "WavPack files. Please select a new file to play\n";
                playBtn.visible = true;
                stopBtn.visible = false;
            }
            else
            {
                s = new flash.media.Sound();
                play();
            }
        }
    }
    
    public function play() : Void 
    {
       // trace("adding callback");
        s.addEventListener("sampleData", sample_unpacker);
        te.text = te.text + "Now Playing\n";
        stopBtn.visible = true;
        sch = s.play();
    }


    static public function stop() : Void
    {
        if ( null != s ) 
        {
            s.removeEventListener("sampleData", sample_unpacker);
            s = null;
        }
        te.text = "Song complete. Please select a new file.";

        playBtn.visible = true;
        stopBtn.visible = false;

    }



    static function sample_unpacker(event : flash.events.SampleDataEvent) : Void 
    {
        var start : Float = 0;
        var end : Float = 0;
        var total_unpacked_samples : Float = 0;
        var temp_buffer : flash.Vector < Int > = new flash.Vector(Defines.SAMPLE_BUFFER_SIZE,true);
	var divisor : Float = 0;

	if(bps == 2)
	{
		divisor = 32767.0;	// 2 to power 15 minus 1
	}
	else
	{
		divisor = 8388607.0;	// 2 to power 23 minus 1
	}

        try
        {
            var samples_unpacked : Float;
            var bytesToWrite : Int = 0;
            var x : Int = 1;
            var numSamples : Float = 0;
          
            
            // You have to unpack a certain amount of samples otherwise it will pause 
            // waiting for the buffer to be filled

            numSamples = Defines.SAMPLE_BUFFER_SIZE / num_channels;
            samples_unpacked = WavPackUtils.WavpackUnpackSamples(wpc, temp_buffer, numSamples );

            total_unpacked_samples += samples_unpacked;

            if(samples_unpacked == 0)
            {
                stop();
            }

            if (samples_unpacked > 0)
            {
                samples_unpacked = samples_unpacked * num_channels; 

               // Currently assumption is 16 or 24 bit 44.1 kHz
               // Flash assumes values will be floats with values less than 1.0
               // Our buffer already has the data in the form LRLRLR... so we can
               // directly use the data, we just need to convert the values
 
               bytesToWrite = Math.floor(samples_unpacked);

               if(num_channels != 1)
               {
                   for(i in 0 ... bytesToWrite)
                   {
                       untyped { 
                               event.data.writeFloat(temp_buffer[i] / divisor); 
                       };
                   }
               }
               else	// mono file, duplicate the sound for each ear
               {
                   for(i in 0 ... bytesToWrite)
                   {
                       untyped { 
                               event.data.writeFloat(temp_buffer[i] / divisor); 
                               event.data.writeFloat(temp_buffer[i] / divisor); // same sound to other channel
                       };
                   }
                   numSamples = numSamples * 2; // double the number of samples as we have replicated the sound in both channels
                   samples_unpacked = samples_unpacked * 2;
               }            
            }
            

            if(samples_unpacked < numSamples )
            {
                for(i in 0 ... Math.floor(numSamples - samples_unpacked ))
                {
                    event.data.writeFloat(0.0);
                }
            }
        }
        catch (err: Dynamic)
        {
            var es = haxe.CallStack.exceptionStack();
            te.text = te.text + haxe.CallStack.toString(es) + "\n";
            te.text = te.text + "Error when extracting WavPack data, sorry";           
        }

    }


    private function new() 
    {
    }

    static function check_version() : Bool {
        if (flash.Lib.current.loaderInfo.parameters.noversioncheck != null)
            return true;

        var vs : String = flash.system.Capabilities.version;
        var vns : String = vs.split(" ")[1];
        var vn : Array<String> = vns.split(",");

        if (vn.length < 1 || Std.parseInt(vn[0]) < 10)
            return false;

        if (vn.length < 2 || Std.parseInt(vn[1]) > 0)
            return true;

        if (vn.length < 3 || Std.parseInt(vn[2]) > 0)
            return true;

        if (vn.length < 4 || Std.parseInt(vn[3]) >= 525)
            return true;

        return false;
    }

    private function onCancel(e: flash.events.Event): Void 
    { 
        te.text = "File Browse Canceled"; 
        fr = null; 
        playBtn.visible = true;
        stopBtn.visible = false;
    } 


    //called when the user selects a file from the browse dialog 

    private function onFileSelect(e: flash.events.Event): Void 
    { 
        //listen for when the file has loaded 

        fr.addEventListener(flash.events.Event.COMPLETE, onLoadComplete); 

        //listen for any errors reading the file 

        fr.addEventListener(flash.events.IOErrorEvent.IO_ERROR, onLoadError); 

        //load the content of the file 

        fr.load(); 

    }

    //called if an error occurs while loading the file contents

    private function onLoadError(e: flash.events.IOErrorEvent):Void 
    { 
        te.text = "Error loading file : " + e.text; 
        playBtn.visible = true;
        stopBtn.visible = false;
    }



    function lets_go() : Void
    {

       //create the FileReference instance 
           
       fr = new flash.net.FileReference(); 
            
       //listen for when they select a file 

       fr.addEventListener(flash.events.Event.SELECT, onFileSelect); 

       //listen for when then cancel out of the browse dialog 

       fr.addEventListener(flash.events.Event.CANCEL,onCancel); 

       //open a native browse dialog that filters for WavPack files 

       fr.browse(FILE_TYPES);

    }
    
    static function overEntry(event : flash.events.MouseEvent)
    {
        playBtn.alpha=0.9;
    }
  
    static function outEntry(event:flash.events.MouseEvent)
    {
        playBtn.alpha=0.7;
    }
    
    // triggered when play button is clicked
  
    static function downEntry(event:flash.events.MouseEvent)
    {
        playBtn.visible = false;
        var tf = new TestFlash();
        tf.lets_go();
    }

    static function overStopEntry(event : flash.events.MouseEvent)
    {
        stopBtn.alpha=0.9;
    }
  
    static function outStopEntry(event:flash.events.MouseEvent)
    {
        stopBtn.alpha=0.7;
    }
    
    // triggered when stop button is clicked
  
    static function downStopEntry(event:flash.events.MouseEvent)
    {
        stopBtn.visible = false;
        playBtn.visible = true;

        if ( null != s ) 
        {
            s.removeEventListener("sampleData", sample_unpacker);
            s = null;
        }

        te.text = "Song stopped. Please select a new file.";
    }


    public static function main()
    {

        if (check_version()) 
        {
        
            // Thanks to http://lionpath.com/haxeflashtutorial/release/chap01.html 
            // for the play button code which I've used here
            
            mc = flash.Lib.current; 
            stage = mc.stage; 
            var g : flash.display.Graphics;

            te = new flash.text.TextField();

            te.autoSize = flash.text.TextFieldAutoSize.LEFT;
            te.y=80;
            mc.addChild(te);

            te.text = "Click the Play button to select a WavPack file to listen to\n";
            te.text = te.text + "WavPack file should be a 16 or 24-bit 44.1kHz file\n";
			te.text = te.text + "Sample rates other than 44.1kHz will not playback correctly";
 
            playBtn = new flash.display.Sprite(); 

            g = playBtn.graphics;
            g.lineStyle(1,0xe5e5e5);
            
            var w : Int = 60;
            var h : Int = 40;
            var colors : Array <UInt> = [0xF5F5F5, 0xA0A0A0];
            var alphas : Array <Int>  = [1, 1];
            var ratios : Array <Int> = [0, 255];
            var matrix : flash.geom.Matrix = new flash.geom.Matrix();
            
            matrix.createGradientBox(w-2, h-2, Math.PI/2, 0, 0);
            g.beginGradientFill(flash.display.GradientType.LINEAR, 
                                colors,
                                alphas,
                                ratios, 
                                matrix, 
                                flash.display.SpreadMethod.PAD, 
                                flash.display.InterpolationMethod.LINEAR_RGB, 
                                0);
            g.drawRoundRect(0,0,w,h,16,16);
            g.endFill();
    
            // draw a triangle
            g.lineStyle(1,0x808080);
            g.beginFill(0x0);
            g.moveTo((w-20)/2,5);
            g.lineTo((w-20)/2+20,h/2);
            g.lineTo((w-20)/2,h-5);
            g.lineTo((w-20)/2,5);
            g.endFill();
    
            // add the drop-shadow filter
            var shadow : flash.filters.DropShadowFilter = new flash.filters.DropShadowFilter(
            4,45,0x000000,0.8,
            4,4,
            0.65, flash.filters.BitmapFilterQuality.HIGH, false, false
            );
    
            var af : Array < flash.filters.BitmapFilter > = new Array();
            af.push(shadow);
            playBtn.filters = af;
            playBtn.alpha = 0.5;
            playBtn.x = 10;
            playBtn.y = 10;


            // add the event listener 
            playBtn.addEventListener(flash.events.MouseEvent.MOUSE_OUT, outEntry); 
            playBtn.addEventListener(flash.events.MouseEvent.MOUSE_OVER, overEntry); 
            playBtn.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, downEntry); 

            mc.addChild(playBtn); 

            stopBtn = new flash.display.Sprite(); 

            g = stopBtn.graphics;
            g.lineStyle(1,0xe5e5e5);
            
            matrix = new flash.geom.Matrix();
            
            matrix.createGradientBox(w-2, h-2, Math.PI/2, 0, 0);
            g.beginGradientFill(flash.display.GradientType.LINEAR, 
                                colors,
                                alphas,
                                ratios, 
                                matrix, 
                                flash.display.SpreadMethod.PAD, 
                                flash.display.InterpolationMethod.LINEAR_RGB, 
                                0);
            g.drawRoundRect(0,0,w,h,16,16);
            g.endFill();
    
            // draw a smaller square
            g.lineStyle(1,0x808080);
            g.beginFill(0x0);
            g.drawRect( (w-25)/2 ,9,25,22);
            g.endFill();
    
            // add the drop-shadow filter
            var shadow : flash.filters.DropShadowFilter = new flash.filters.DropShadowFilter(
            4,45,0x000000,0.8,
            4,4,
            0.65, flash.filters.BitmapFilterQuality.HIGH, false, false
            );
    
            var af : Array < flash.filters.BitmapFilter > = new Array();
            af.push(shadow);
            stopBtn.filters = af;
            stopBtn.alpha = 0.5;
            stopBtn.x = 10;
            stopBtn.y = 10;


            // add the event listener 
            stopBtn.addEventListener(flash.events.MouseEvent.MOUSE_OUT, outStopEntry); 
            stopBtn.addEventListener(flash.events.MouseEvent.MOUSE_OVER, overStopEntry); 
            stopBtn.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, downStopEntry); 

            mc.addChild(stopBtn); 

            stopBtn.visible = false;

        } 
        else 
        {
            trace("You need a newer Flash Player.");
            trace("Your version: " + flash.system.Capabilities.version);
            trace("The minimum required version: 10.0.0.525");
        }
       
    }
}
