package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

class ChartNote extends ScriptSpriteGroup
{
    final NOTE_SIZE:Int;

    var texture:FlxSprite;

    public var tail:FlxSprite;

    public var time:Float;

    public var length(default, set):Float;
    function set_length(value:Float):Float
    {
        length = value;

        tail.scale.y = NOTE_SIZE * (value / Conductor.stepCrochet);
        tail.updateHitbox();

        return length;
    }

    public function new(data:Int, noteSize:Int, anim:String, ?time:Float, ?length:Float)
    {
        super();

        NOTE_SIZE = noteSize;

        texture = new FlxSprite();
        texture.frames = Paths.getSparrowAtlas('noteSkins/NOTE_assets');
        texture.animation.addByPrefix('idle', anim, 1, false);
        texture.animation.play('idle');
        texture.setGraphicSize(NOTE_SIZE, NOTE_SIZE);
        texture.updateHitbox();

        tail = new FlxSprite().makeGraphic(Math.floor(NOTE_SIZE / 5), 1);
        tail.x = texture.width / 2 - tail.width / 2;
        tail.y = texture.height / 2;

        add(tail);
        add(texture);

        reset(anim, data, time ?? 0, length ?? 0);
    }

    public function reset(anim:String, data:Int, time:Float, length:Float)
    {
        texture.animation.addByPrefix('idle', anim, 1, false);
        texture.animation.play('idle');
        
        this.time = time;
        this.length = length;

        this.x = data * NOTE_SIZE;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        alpha = Conductor.songPosition <= time ? 1 : 0.5;
    }
}