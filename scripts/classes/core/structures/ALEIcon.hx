package core.structures;

import core.enums.ALEIconAnimationType;

typedef ALEIcon = {
    var texture:String;
    var animationType:ALEIconAnimationType;
    var animations:Array<ALEIconAnimation>;
    var scale:Point;
    var bopScale:Point;
    var bopModulo:Int;
    var lerp:Float;
    var format:String;
    var flipX:Bool;
    var flipY:Bool;
    var offset:Point;
}