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

    var background:FlxSprite;

    var notes:FlxTypedGroup<ChartNote>;

    var pointer:FlxSprite;

    var animations:Array<String> = [];

    public function new(noteSize:Int, strums:Int, length:Int, linePos:Int, ?anims:Array<String>)
    {
        super();

        animations = anims ?? ['purple0', 'blue0', 'green0', 'red0'];

        NOTE_SIZE = noteSize;

        background = new ALEMouseSprite(0, 0, FlxGridOverlay.createGrid(NOTE_SIZE, NOTE_SIZE, NOTE_SIZE * strums, NOTE_SIZE * length, true, ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -75), ALEUIUtils.adjustColorBrightness(ALEUIUtils.COLOR, -50)));
        add(background);
        background.onOverlapChange = (isOver) -> {
            pointer.exists = isOver;
            
            pointer.color = FlxColor.WHITE;
        };

        notes = new FlxTypedSpriteGroup<ChartNote>();
        add(notes);

        pointer = new FlxSprite().makeGraphic(NOTE_SIZE, NOTE_SIZE);
        pointer.alpha = 0.25;
        add(pointer);
        pointer.exists = false;

        var positionLine:FlxSprite = new FlxSprite(0, linePos).makeGraphic(Math.floor(background.width), 5);
        add(positionLine);
        positionLine.scrollFactor.set();

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

        pointer.x = x + Math.floor(mousePos.x / NOTE_SIZE) * NOTE_SIZE;
        pointer.y = y + Math.floor(mousePos.y / NOTE_SIZE) * NOTE_SIZE;

        if (longNoteInput != null)
        {
            if (pointer.y >= longNoteInput.y)
                longNoteInput.length = (pointer.y - longNoteInput.y) / NOTE_SIZE * Conductor.stepCrochet;
        }

        if (input != null)
            if (input)
                input = null;

        if ((FlxG.mouse.justPressed && !FlxG.mouse.pressedRight) || (FlxG.mouse.justPressedRight && !FlxG.mouse.pressed))
        {
            pointer.color = FlxG.mouse.justPressed ? FlxColor.GRAY : FlxColor.RED;

            input = FlxG.mouse.justPressed ? true : false;
        }

        if (FlxG.mouse.justReleased || FlxG.mouse.justReleasedRight)
        {
            pointer.color = FlxG.mouse.pressed ? FlxColor.GRAY : FlxG.mouse.pressedRight ? FlxColor.RED : FlxColor.WHITE;

            input = null;

            longNoteInput = null;
        }

        if (input != null)
        {
            if (input)
            {
                addNote();
            } else {
                for (note in notes)
                    if (FlxG.mouse.overlaps(note))
                        notes.remove(note);
            }
        }
    }

    function addNote()
    {
        var noteData:Int = Math.floor((pointer.x - x) / NOTE_SIZE);

        var note:ChartNote = new ChartNote(noteData, NOTE_SIZE, animations[noteData]);
        note.x = pointer.x;
        note.y = pointer.y;

        note.parent = super;

        notes.add(note);

        longNoteInput = note;
    }
}