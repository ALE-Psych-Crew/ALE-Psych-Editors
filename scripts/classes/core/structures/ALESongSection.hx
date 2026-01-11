package core.structures;

import flixel.util.typeLimit.OneOfTwo;

typedef ALESongSection = {
    var notes:Array<Array<EitherType<Float, Array<Int>>>>;
    var camera:Array<Int>;
    var bpm:Float;
    var changeBPM:Bool;
}