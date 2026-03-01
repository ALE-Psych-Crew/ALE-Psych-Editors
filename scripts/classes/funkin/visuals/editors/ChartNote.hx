package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

import funkin.visuals.shaders.RGBPalette;
import funkin.visuals.shaders.RGBShaderReference;

import ale.ui.ALEUIUtils;

class ChartNote extends ScriptSpriteGroup
{
    public var cellSize:Float;

    public var texture:FlxSprite;
    public var tail:FlxSprite;
    
    public var textureShader:RGBShaderReference;

    public var time:Float;

    public var config:ALEStrumLine;

    public var data:Int;

    public var selected(default, set):Bool = false;
    function set_selected(value:Bool)
    {
        if (selected ?? false == value)
            return selected;

        selected = value;

        updateShader();

        return selected;
    }

    final currentColors:Null<Array<Int>> = null;

    final selectColors:Null<Array<Int>> = [
        ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50),
        ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, 50),
        ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, 25)
    ];
    
    public var length(default, set):Float;
    function set_length(value:Float):Float
    {
        if (length == value)
            return length;

        length = Math.max(0, value);

        tail.scale.y = length <= 0 ? 0 : cellSize * (value / Conductor.stepCrochet);

        tail.updateHitbox();
        tail.x = x + texture.width / 2 - tail.width / 2;
        tail.y = y + texture.height / 2;

        return length;
    }

    public var type:String;

    public var index:Int;

    public function new(cellSize:Float, config:ALEStrumLine)
    {
        super();

        this.config = config;

        this.cellSize = cellSize;

        texture = new FlxSprite();
        texture.frames = Paths.getMultiAtlas([for (skin in config.noteTextures) 'notes/' + skin]);

		textureShader = new RGBShaderReference(texture, new RGBPalette());

        tail = new FlxSprite().makeGraphic(Math.floor(cellSize / 5), 1, FlxColor.GRAY);
        tail.alpha = 0.75;

        add(tail);
        add(texture);
    }

    public function reset(time:Float, data:Int, length:Float, type:String)
    {
        final anim:String = config.strums[data].note;

        texture.animation.addByPrefix(anim, anim, 1);
        texture.animation.play(anim, true);
        texture.setGraphicSize(cellSize, cellSize);
        texture.updateHitbox();

        currentColors = [for (color in config.strums[data].shader) CoolUtil.colorFromString(color)];

        updateShader();

        this.time = time;
        this.data = data;
        this.length = length;
        this.type = type;

        this.x = data * cellSize;
        this.y = (time - CoolUtil.snapNumber(Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time, Conductor.sectionCrochet)) / Conductor.stepCrochet * cellSize;
    }

    function updateShader()
    {
        final colors:Null<Array<Int>> = selected ? selectColors : currentColors;

        textureShader.enabled = colors != null;

        if (textureShader.enabled)
        {
            textureShader.r = colors[0];
            textureShader.g = colors[1];
            textureShader.b = colors[2];
            
            tail.color = textureShader.r;
        } else {
            tail.color = FlxColor.WHITE;
        }
    }

    var curTime:Float = 0;

    var hit:Bool = false;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        final newHit:Bool = Conductor.songPosition > time;

        if (newHit != hit)
        {
            hit = newHit;

            if (FlxG.sound.music.playing)
                FlxG.sound.play(Paths.sound('editors/noteHit'));
        }

        curTime = selected ? curTime + elapsed : 0;

        texture.alpha = selected ? Math.sin(curTime * 2) * 0.3 + 0.7 : (hit ? 0.5 : 1);

        tail.alpha = texture.alpha * 0.75;
    }
}