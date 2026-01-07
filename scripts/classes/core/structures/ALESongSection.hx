package core.structures;

typedef ALESongSection = {
    var notes:Array<Array<Float>>;
    var camera:Int;
    var isPlayer:Bool;
    var bpm:Float;
    var changeBPM:Bool;
}