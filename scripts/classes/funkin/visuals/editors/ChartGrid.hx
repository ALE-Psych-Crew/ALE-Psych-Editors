package funkin.visuals.editors;

import scripting.haxe.ScriptSpriteGroup;

import flixel.addons.display.FlxBackdrop;
import flixel.addons.display.FlxGridOverlay;

import ale.ui.ALEUIUtils;
import ale.ui.ALEMouseSprite;

import flixel.math.FlxPoint;

import funkin.visuals.editors.ChartNote;

class ChartGrid extends ScriptSpriteGroup
{
    final NOTE_SIZE:Int;

    public var background:FlxSprite;

    var notes:FlxTypedSpriteGroup<ChartNote>;

    var pointer:FlxSprite;

    public var animations:Array<String> = [];

    var notePool:Array<ChartNote> = [];

    public final strums:Array<ChartStrumConfig>;

    public var sections:Array<Array<JSONNote>> = [];

    public final textures:Array<String> = [];

    public function new(noteSize:Int, length:Int, linePos:Int, ?strs:Array<ChartStrumConfig>, ?sprites:Array<String>)
    {
        super();

        strums = strs ?? [
            {
                animation: "purple0",
                shader: [0xFFC24B99, 0xFFFFFFFF, 0xFF3C1F56]
            },
            {
                animation: "blue0",
                shader: [0xFF00FFFF, 0xFFFFFFFF, 0xFF1542B7]
            },
            {
                animation: "green0",
                shader: [0xFF12FA05, 0xFFFFFFFF, 0xFF0A4447]
            },
            {
                animation: "red0",
                shader: [0xFFF9393F, 0xFFFFFFFF, 0xFF651038]
            }
        ];

        textures = sprites ?? ['NOTE_assets'];

        NOTE_SIZE = noteSize;

        background = new ALEMouseSprite(0, 0, FlxGridOverlay.createGrid(NOTE_SIZE, NOTE_SIZE, NOTE_SIZE * strums.length, NOTE_SIZE * length, true, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -75), ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)));
        add(background);
        background.onOverlapChange = (isOver) -> { pointer.exists = isOver; };

        notes = new FlxTypedSpriteGroup<ChartNote>();
        add(notes);

        pointer = new FlxSprite().makeGraphic(NOTE_SIZE, NOTE_SIZE);
        pointer.alpha = 0.25;
        add(pointer);
        pointer.exists = false;

        var positionLine:FlxSprite = new FlxSprite(0, linePos).makeGraphic(Math.floor(background.width), 5);
        add(positionLine);
        positionLine.scrollFactor.set(1);

        var middleMask:FlxSprite = new FlxSprite(0, background.height / 2).makeGraphic(Math.floor(background.width), Math.floor(background.height / 2));
        middleMask.color = FlxColor.BLACK;
        middleMask.alpha = 0.5;
        add(middleMask);
    }

    var _lastSec:Int = -1;

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if (_lastSec != Conductor.curSection)
        {
            _lastSec = Conductor.curSection;

            updateSection(_lastSec);
        }

        updatePointer();
    }

    var mousePos(get, never):FlxPoint;
    function get_mousePos():FlxPoint
    {
        return FlxG.mouse.getWorldPosition(cameras[0]);
    }

    var input:Null<Bool> = null;

    var longNoteInput:Null<ChartNote> = null;

    function updatePointer()
    {
        if (!pointer.exists)
            return;

        pointer.x = x + Math.floor((mousePos.x - x) / NOTE_SIZE) * NOTE_SIZE;
        pointer.y = y + Math.floor((mousePos.y - y) / NOTE_SIZE) * NOTE_SIZE;

        if (longNoteInput != null)
        {
            if (pointer.y >= longNoteInput.y)
            {
                longNoteInput.length = (pointer.y - longNoteInput.y) / NOTE_SIZE * Conductor.stepCrochet;
                
                sections[Conductor.curSection][longNoteInput.index].length = longNoteInput.length;
            }
        }

        if (input != null && input)
            input = null;

        if ((FlxG.mouse.justPressed && !FlxG.mouse.pressedRight) || (FlxG.mouse.justPressedRight && !FlxG.mouse.pressed))
            input = FlxG.mouse.justPressed ? true : false;

        if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight)
        {
            input = null;

            longNoteInput = null;
        }

        if (input != null)
        {
            var overlapedNote:ChartNote = null;
            
            for (note in notes)
            {
                if (!note.alive)
                    continue;

                if (FlxG.mouse.overlaps(note.texture))
                {
                    overlapedNote = note;

                    break;
                }
            }

            if (input)
            {
                if (overlapedNote == null)
                    addNote();
            } else {
                if (overlapedNote != null)
                {
                    sections[Conductor.curSection][overlapedNote.index] = null;

                    notes.remove(overlapedNote);

                    notePool.push(overlapedNote);
                }
            }
            
            pointer.color = input ? FlxColor.GRAY : FlxColor.RED;
        } else {
            pointer.color = FlxColor.WHITE;
        }
    }

    function addNote(?customData:Int, ?customTime:Float, ?length:Float, ?type:String, ?push:Bool)
    {
        sections[Conductor.curSection] ??= [];

        final data:Int = customData ?? Math.floor((pointer.x - x) / NOTE_SIZE);

        final config:ChartStrumConfig = strums[data];

        final time:Float = customTime ?? (pointer.y - y <= 0 ? 0 : (pointer.y - y) / (background.height / 2) * (background.height / 2 / NOTE_SIZE) * Conductor.stepCrochet);

        final anim:String = config.animation;

        final length:Float = length ?? 0;

        final type:String = type ?? '';

        var note:ChartNote;
        
        if (notePool.length <= 0)
            note = new ChartNote(textures, NOTE_SIZE);
        else
            note = notePool.pop();

        note.reset(anim, data, time, length, type, config.shader);

        note.index = sections[Conductor.curSection].length;

        notes.add(note);

        if (push ?? true)
        {
            sections[Conductor.curSection].push(
                {
                    time: time,
                    data: data,
                    length: length,
                    type: type
                }
            );

            longNoteInput = note;
        }
    }

    function updateSection(curSection:Int)
    {
        longNoteInput = null;

        for (note in notes)
        {
            notePool.push(note);

            notes.remove(note);
        }

        var jsonSection:Array<JSONNote> = sections[curSection];

        jsonSection ??= [];

        for (note in jsonSection)
            if (note != null)
                addNote(note.data, note.time, note.length, note.type, false);
    }

    override function destroy()
    {
        for (note in notePool)
        {
            note.destroy();

            note = null;
        }

        super.destroy();
    }
}