package core.structures;

typedef ALESong = {
    var strumLines:Array<ALESongStrumline>;
    var sections:Array<ALESongSection>;
    var format:String;
    var bpm:Float;
    var stepsPerBeat:Int;
    var beatsPerSection:Int;
}