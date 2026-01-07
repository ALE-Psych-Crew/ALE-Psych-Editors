package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

import ale.ui.ALEUIUtils;

import funkin.visuals.shaders.RGBPalette;
import funkin.visuals.shaders.RGBShaderReference;

class ChartNote extends ScriptSpriteGroup
{
    final CHARTING_STATE:MusicBeatState = MusicBeatState.instance;

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

    var lastShader:Null<Array<Int>>;

    public function reset(anim:String, data:Int, time:Float, length:Float, type:String, ?shader:Null<Array<Int>>)
    {
        texture.animation.addByPrefix(anim, anim, 1, false);
        texture.animation.play(anim);
        texture.setGraphicSize(NOTE_SIZE, NOTE_SIZE);
        texture.updateHitbox();
        
        this.time = time;
        this.length = length;

        this.data = data;

        this.x = data * NOTE_SIZE;

        this.y = (time - CoolUtil.snapNumber(Conductor.songPosition - CHARTING_STATE.bpmChangeMap[CHARTING_STATE.curBPMIndex].time, Conductor.sectionCrochet)) / Conductor.stepCrochet * NOTE_SIZE;

        this.type = type;

        lastShader = shader;

        setShader();

        selected = false;
    }

    final SELECT_SHADER:Array<Int> = [
        ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50),
        ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, 50),
        ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, 25)
    ];

    function setShader()
    {
        tail.color = FlxColor.WHITE;

        textureShader.enabled = lastShader != null;

        if (textureShader.enabled)
        {
            textureShader.r = CoolUtil.colorFromString(lastShader[0]);
            textureShader.g = CoolUtil.colorFromString(lastShader[1]);
            textureShader.b = CoolUtil.colorFromString(lastShader[2]);

            tail.color = textureShader.r;
        }
    }

    var selectedAlpha:Float = 1;

    var selectedTime:Float = 0;

    public var selected(default, set):Null<Bool>;
    function set_selected(val:Null<Bool>):Null<Bool>
    {
        selected = val;

        if (selected)
        {
            selectedTime = 0;
            
            textureShader.r = SELECT_SHADER[0];
            textureShader.g = SELECT_SHADER[1];
            textureShader.b = SELECT_SHADER[2];

            tail.color = textureShader.b;
        } else {
            selectedAlpha = 1;

            setShader();
        }

        return selected;
    }

    public var selectedIndex:Null<Int>;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (selected)
        {
            selectedTime += elapsed * 3;

            selectedAlpha = 0.75 + Math.sin(selectedTime) * 0.25;
        }

        texture.alpha = (Conductor.songPosition <= time ? 1 : 0.5) * selectedAlpha;

        tail.alpha = texture.alpha * 0.75;
    }
}