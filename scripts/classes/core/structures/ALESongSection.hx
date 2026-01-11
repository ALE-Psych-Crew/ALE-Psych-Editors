package core.structures;

import flixel.util.typeLimit.OneOfTwo;

typedef ALESongSection = {
    var notes:Array<Array<Dynamic>>;
    var camera:Array<Int>;
    var bpm:Float;
    var changeBPM:Bool;
}