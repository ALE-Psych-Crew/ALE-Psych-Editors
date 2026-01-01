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

    var notes:FlxTypedGroup<ChartNote>;

    var pointer:FlxSprite;

    var animations:Array<String> = [];

    public var jsonNotes:Array<Array<Int>> = [];

    public function new(noteSize:Int, strums:Int, length:Int, linePos:Int, ?anims:Array<String>)
    {
        super();

        animations = anims ?? ['purple0', 'blue0', 'green0', 'red0'];

        NOTE_SIZE = noteSize;

        background = new ALEMouseSprite(0, 0, FlxGridOverlay.createGrid(NOTE_SIZE, NOTE_SIZE, NOTE_SIZE * strums, NOTE_SIZE * length, true, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -75), ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)));
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

    override function update(elapsed:Float)
    {
        super.update(elapsed);

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
                longNoteInput.length = (pointer.y - longNoteInput.y) / NOTE_SIZE * Conductor.stepCrochet;
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
                    return;

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
                    jsonNotes[Conductor.curSection][overlapedNote.index] = null;

                    notes.remove(overlapedNote);
                }
            }
            
            pointer.color = input ? FlxColor.GRAY : FlxColor.RED;
        } else {
            pointer.color = FlxColor.WHITE;
        }
    }

    function addNote(?customData:Int, ?customTime:Float, ?length:Float)
    {
        jsonNotes[Conductor.curSection] ??= [];

        var noteData:Int = Math.floor((pointer.x - x) / NOTE_SIZE);

        var noteTime:Float = (pointer.y - y) / (background.height / 2) * (background.height / 2 / NOTE_SIZE) * Conductor.stepCrochet;

        var note:ChartNote = new ChartNote(customData ?? noteData, NOTE_SIZE, animations[noteData], customTime ?? (pointer.y - y <= 0 ? 0 : noteTime), length);
        note.index = jsonNotes[Conductor.curSection].length;

        jsonNotes[Conductor.curSection].push(
            [
                note.time,
                note.data,
                note.length
            ]
        );

        notes.add(note);

        longNoteInput = note;

        debugTrace(jsonNotes);
    }
}