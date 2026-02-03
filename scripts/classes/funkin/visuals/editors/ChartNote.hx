package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

class ChartNote extends ScriptSpriteGroup
{
    public var cellSize:Float;

    public var texture:FlxSprite;
    public var tail:FlxSprite;

    public var time:Float;

    public var data:Int;
    
    public var length(default, set):Float;
    function set_length(value:Float):Float
    {
        length = value;

        tail.scale.y = cellSize * (value / Conductor.stepCrochet);
        tail.updateHitbox();
        tail.x = x + texture.width / 2 - tail.width / 2;
        tail.y = y + texture.height / 2;

        return length;
    }

    public var type:String;

    public var index:Int;

    public function new(cellSize:Float)
    {
        super();

        this.cellSize = cellSize;

        texture = new FlxSprite();

        texture.makeGraphic(cellSize, cellSize, FlxColor.CYAN);

        tail = new FlxSprite().makeGraphic(Math.floor(cellSize / 5), 1, FlxColor.GRAY);

        add(tail);
        add(texture);
    }

    public function reset(time:Float, data:Int, length:Float, type:String)
    {
        texture.setGraphicSize(cellSize, cellSize);
        texture.updateHitbox();

        this.time = time;
        this.data = data;
        this.length = length;
        this.type = type;

        this.x = data * cellSize;
        this.y = (time - CoolUtil.snapNumber(Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time, Conductor.sectionCrochet)) / Conductor.stepCrochet * cellSize;
    }
}