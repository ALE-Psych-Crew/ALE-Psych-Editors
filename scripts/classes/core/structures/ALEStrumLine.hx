package core.structures;

typedef ALEStrumLine = {
    var position:Point;
    var strumScale:Float;
    var noteScale:Float;
    var splashScale:Float;
    var space:Int;
    var strums:Array<ALEStrum>;
    var strumFramerate:Int;
    var splashFramerate:Int;
    var splashTextures:Array<String>;
    var noteTextures:Array<String>;
    var strumTextures:Array<String>;
}