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

    public var note:FunkinSprite;

    var sustain:FlxSprite;

    public var index:Int = -1;

    public final noteShader:RGBShaderReference;

    public var time(default, set):Float;
    function set_time(value:Float):Float
    {
        if (time == value)
            return time;

        time = value;

        y = (time - CoolUtil.snapNumber(Conductor.songPosition - Conductor.bpmChangeMap[Conductor.curBPMIndex].time, Conductor.sectionCrochet)) / Conductor.stepCrochet * EditorUtil.NOTE_SIZE;

        return time;
    }

    public var data(default, set):Int;
    function set_data(value:Float):Float
    {
        if (data == value)
            return data;

        data = value % strumLineConfig.length;

        final curData = strumLineConfig[data];

        note.playAnim(curData.note);
        note.setGraphicSize(EditorUtil.NOTE_SIZE, EditorUtil.NOTE_SIZE);
        note.updateHitbox();

        sustain.x = x + note.width / 2 - sustain.width / 2;

        shaderColor = [for (color in curData.shader) CoolUtil.colorFromString(color)];

        updateShader();

        x = EditorUtil.NOTE_SIZE * data;
        
        return length;
    }

    public var length(default, set):Float;
    function set_length(value:Float):Float
    {
        if (length == value)
            return length;

        length = Math.max(value, 0);

        sustain.scale.y = length <= 0 ? 0 : EditorUtil.NOTE_SIZE * (length / Conductor.stepCrochet);
        sustain.updateHitbox();

        return length;
    }

    public var type:String = '';

    public var selected(default, set):Bool;
    function set_selected(value:Float)
    {
        if (selected == value)
            return selected;

        selected = value;

        updateShader();

        curTime = 0;

        return selected;
    }

    public function new(id:String, strl:JsonStrumLineConfig)
    {
        super();

        strumLineConfig = strl;

        sustain = new FlxSprite(0, EditorUtil.NOTE_SIZE / 2).makeGraphic(Math.floor(EditorUtil.NOTE_SIZE / 5), 1);
        sustain.alpha = 0.25;
        add(sustain);

        note = SpriteUtil.spriteFromJson(null, Paths.json('data/notes/' + id), 'notes/');
        add(note);
        
		noteShader = new RGBShaderReference(note, new RGBPalette());

        time = 0;
        data = 0;
        length = 0;
        type = '';

        selected = false;
    }

    var curTime:Float = 0;

    public var lastTime:Float = -1;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (lastTime != Conductor.songPosition)
        {
            if (FlxG.sound.music.playing && lastTime < time && Conductor.songPosition >= time)
                FlxG.sound.play(Paths.sound('editors/noteHit'), 0.75);

            lastTime = Conductor.songPosition;
        }

        final baseAlpha:Float = Conductor.songPosition >= time ? 0.5 : 1;

        if (selected)
        {
            curTime += elapsed;

            note.alpha = baseAlpha * 0.75 + Math.sin(curTime * 4) * baseAlpha * 0.25;
        } else {
            note.alpha = baseAlpha;
        }

        sustain.alpha = note.alpha * 0.25;
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

        noteShader.enabled = colors != null;
        
        if (noteShader.enabled)
        {
            noteShader.r = colors[0];
            noteShader.g = colors[1];
            noteShader.b = colors[2];
            
            sustain.color = selected ? noteShader.g : noteShader.r;
        } else {
            sustain.color = FlxColor.WHITE;
        }
    }
}