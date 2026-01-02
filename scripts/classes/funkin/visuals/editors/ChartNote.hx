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
        tail.x = x + texture.width / 2 - tail.width / 2;
        tail.y = y + texture.height / 2;

        return length;
    }

    public var index:Int;

    public var data:Int;

    public var type:String = '';

    public function new(?sprites:Array<String>, noteSize:Int)
    {
        super();

        NOTE_SIZE = noteSize;

        texture = new FlxSprite();
        texture.frames = Paths.getMultiAtlas([for (spr in sprites) 'noteSkins/' + spr]);
        
		textureShader = new RGBShaderReference(texture, new RGBPalette());

        tail = new FlxSprite().makeGraphic(Math.floor(NOTE_SIZE / 5), 1, FlxColor.GRAY);

        add(tail);
        add(texture);
    }

    public function reset(anim:String, data:Int, time:Float, length:Float, type:String, ?shader:Array<Int>)
    {
        texture.animation.addByPrefix(anim, anim, 1, false);
        texture.animation.play(anim);
        texture.setGraphicSize(NOTE_SIZE, NOTE_SIZE);
        texture.updateHitbox();
        
        this.time = time;
        this.length = length;

        this.data = data;

        this.x = data * NOTE_SIZE;
        this.y = time / Conductor.stepCrochet * NOTE_SIZE;

        this.type = type;

        tail.color = FlxColor.GRAY;

        textureShader.enabled = shader != null;

        if (textureShader.enabled)
        {
            textureShader.r = CoolUtil.colorFromString(shader[0]);
            textureShader.g = CoolUtil.colorFromString(shader[1]);
            textureShader.b = CoolUtil.colorFromString(shader[2]);

            tail.color = textureShader.r;
        }
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        texture.alpha = Conductor.songPosition <= time ? 1 : 0.5;
        tail.alpha = texture.alpha * 0.75;
    }
}