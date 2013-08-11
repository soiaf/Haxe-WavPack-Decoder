////////////////////////////////////////////////////////////////////////////
//            Haxe Implementation of WavPack Decoder                      //
//              Copyright (c) 2008 - 2013 Peter McQuillan                 //
//                          All Rights Reserved.                          //
//      Distributed under the BSD Software License (see license.txt)      //
////////////////////////////////////////////////////////////////////////////

This package contains a Haxe implementation of the tiny version of the WavPack 
4.40 decoder. It is packaged with a demo command-line programs that accept a
WavPack audio file as input and output a RIFF wav file (with the filename 
output.wav). 
The demo command-line programs can generate source code in the following languages:
Neko, C++, C#, Java and Javascript

The program was developed using Haxe compiler 3.0

===
To compile the .hx files for use with Neko, use the following command

haxe nekoWavPack.hxml

To run the demo program, use the following command

neko wavpack.n  <input.wv>

where input.wv is the name of the WavPack file you wish to decode to a WAV file.
===
To produce C++ output and an executable made from this C++ code, you will need to
have a C++ compiler installed on your computer.
You will also need to install the hxcpp haXe library.

1) Make sure haxelib is setup, you can do this by running

haxelib setup

2) You then need to install hxcpp

haxelib install hxcpp

To produce the C++ output, use the following command

haxe cppWavPack.hxml

This will create a directory called haxecpp. In this directory you will find all
the generated C++ files.
You will also find an executable called CPPWvDemo

To run this executable, use the following command

./CPPWvDemo <input.wv>

where input.wv is the name of the WavPack file you wish to decode to a WAV file.

==
To generate a Java output:

haxe javaWavPack.hxml

To generate a C# output

haxe csWavPack.hxml
===
It is also possible to make a demo Flash output file. The demo program currently
only works correctly with (16-bit or 24-bit) 44.1 kHz files.

To make the Flash swf, simply run

haxe flashWavPack.hxml

When you call the SWF file it will display a Play button, clicking on this will 
bring up a file browser prompt. Using this file browser, select a WavPack file 
you wish to play.

===
It is also possible to make a demo JavaScript player. The demo has been tested with Firefox 
and Chrome.

To make the JavaScript code, run

haxe jsWavPack.hxml

The associated HTML page for this code is WavPackJS.html
This html file also uses MyWavPack.js (generated from the above haxe command)
and the XAudioJS directory.

The Javascript playback routines use XAudioJS, for more details:
https://github.com/grantgalitz/XAudioJS

===

The haXe implementation of the WavPack decoder will not handle "correction" files,
and plays only the first two channels of multi-channel files. 
It also will not accept WavPack files from before version 4.0.

Please direct any questions or comments to beatofthedrum@gmail.com