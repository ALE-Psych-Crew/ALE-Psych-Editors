package core.structures;

typedef ALEStage = {
    @:optional var directory:String;
    @:optional var speed:Float;
    @:optional var objects:Array<ALEStageObject>;
    @:optional var zoom:Float;
    @:optional var ui:String;
    @:optional var characterOffset:ALEStageOffset;
    @:optional var cameraOffset:ALEStageOffset;
}