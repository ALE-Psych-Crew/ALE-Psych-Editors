package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

import ale.ui.ALEUIUtils;

import funkin.visuals.shaders.RGBPalette;
import funkin.visuals.shaders.RGBShaderReference;

class ChartNote extends ScriptSpriteGroup
{
    final NOTE_SIZE:Int;

    public var texture:FlxSprite;

    public var textureShader:RGBShaderReference;

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

    public var index:Int;

    public var data:Int;

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
        
		textureShader = new RGBShaderReference(texture, new RGBPalette());
        textureShader.r = FlxColor.fromRGB(25, 25, 25);
        textureShader.g = ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, 50);
        textureShader.b = ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, 25);

        tail = new FlxSprite().makeGraphic(Math.floor(NOTE_SIZE / 5), 1, ALEUIUtils.COLOR);
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

        this.data = data;

        this.x = data * NOTE_SIZE;
        this.y = time / Conductor.stepCrochet * NOTE_SIZE;
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        texture.alpha = Conductor.songPosition <= time ? 1 : 0.5;
        tail.alpha = texture.alpha * 0.75;
    }
}