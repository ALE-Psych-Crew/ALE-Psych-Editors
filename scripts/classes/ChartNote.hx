package;

// import core.structures.JsonStrumLine;

import funkin.visuals.shaders.RGBShaderReference;
import funkin.visuals.shaders.RGBPalette;

import utils.cool.SpriteUtil;

import ale.ui.UIUtils;

import EditorUtil;

class ChartNote extends scripting.haxe.ScriptedFlxSpriteGroup
{
    var strumLineConfig:JsonStrumLineConfig;

    var texture:FunkinSprite;
    var sustain:FlxSprite;

    public var textureShader:RGBShaderReference;

    public var time(default, set):Float;
    function set_time(value:Float):Float
    {
        time = value;

        y = (time - CoolUtil.snapNumber(Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time, Conductor.sectionCrochet)) / Conductor.stepCrochet * EditorUtil.NOTE_SIZE;

        return time;
    }

    public var data(default, set):Int;
    function set_data(value:Float):Float
    {
        data = value % strumLineConfig.length;

        final curData = strumLineConfig[data];

        texture.playAnim(curData.note);
        texture.setGraphicSize(EditorUtil.NOTE_SIZE, EditorUtil.NOTE_SIZE);
        texture.updateHitbox();

        sustain.x = x + texture.width / 2 - sustain.width / 2;

        shaderColor = [for (color in curData.shader) CoolUtil.colorFromString(color)];

        updateShader();

        x = EditorUtil.NOTE_SIZE * data;
        
        return length;
    }

    public var length(default, set):Float;
    function set_length(value:Float):Float
    {
        length = Math.max(value, 0);

        sustain.scale.y = length <= 0 ? 1 : EditorUtil.NOTE_SIZE * (length / Conductor.stepCrochet);
        sustain.updateHitbox();

        return length;
    }

    public var type:String = '';

    public var selected:Bool = false;

    public function new(id:String, strl:JsonStrumLineConfig)
    {
        super();

        strumLineConfig = strl;

        sustain = new FlxSprite(0, EditorUtil.NOTE_SIZE / 2).makeGraphic(Math.floor(EditorUtil.NOTE_SIZE / 5), 1);
        sustain.alpha = 0.75;
        add(sustain);

        texture = SpriteUtil.spriteFromJson(null, Paths.json('data/notes/' + id), 'notes/');
        add(texture);
        
		textureShader = new RGBShaderReference(texture, new RGBPalette());

        time = 0;
        data = 0;
        length = 0;
        type = '';
    }

    var shaderColor:Null<Array<FlxColor>>;

    final selectColors:Null<Array<Int>> = [
        UIUtils.adjustColorBrightness(UIUtils.COLOR, -50),
        UIUtils.adjustColorBrightness(UIUtils.COLOR, 50),
        UIUtils.adjustColorBrightness(UIUtils.COLOR, 25)
    ];

    public function updateShader()
    {
        final colors:Null<Array<Int>> = selected ? selectColors : shaderColor;

        textureShader.enabled = colors != null;
        
        if (textureShader.enabled)
        {
            textureShader.r = colors[0];
            textureShader.g = colors[1];
            textureShader.b = colors[2];
            
            sustain.color = selected ? textureShader.g : textureShader.r;
        } else {
            sustain.color = FlxColor.WHITE;
        }
    }
}