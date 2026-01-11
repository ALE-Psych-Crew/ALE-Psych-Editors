package core.structures;

import core.enums.CharacterType;

typedef ALESongStrumline = {
    var file:String;
    var position:Point;
    var rightToLeft:Bool;
    var visible:Float;
    var characters:Array<String>;
    var type:CharacterType;
};