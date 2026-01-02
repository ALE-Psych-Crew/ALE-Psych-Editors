package core.structures;

typedef ALESongStrumLine = {
    var position:Array<Float>;
    var scale:Float;
    var space:Float;
    var textures:Array<String>;
    var spashTextures:Array<String>;
    var strums:Array<ALESongStrum>;
}